import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _userId;
  bool _isCartLoaded = false;
  bool get isCartLoaded => _isCartLoaded;

  CartService() {
    _init();
  }

  List<CartItem> get items => _items;

  Future<void> _init() async {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        loadCartFromFirestore();
      } else {
        _userId = null;
        clearCart();
      }
    });
  }

  Future<void> loadCartFromFirestore() async {
    if (_userId == null) {
      _isCartLoaded = true;
      notifyListeners();
      return;
    }
    _isCartLoaded = false;
    notifyListeners();
    try {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('cart');
      final snapshot = await cartRef.get();
      _items.clear();
      for (var doc in snapshot.docs) {
        _items.add(CartItem.fromJson(doc.data()));
      }
      print('Cart loaded from Firestore: \\${_items.length} items');
    } catch (e) {
      print('Error loading cart from Firestore: \\${e.toString()}');
    }
    _isCartLoaded = true;
    notifyListeners();
  }

  Future<void> _saveCartToFirestore() async {
    if (_userId == null) return;
    try {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('cart');
      final batch = FirebaseFirestore.instance.batch();
      final existing = await cartRef.get();
      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (var item in _items) {
        final docRef = cartRef.doc(item.productId);
        batch.set(docRef, item.toJson());
      }
      await batch.commit();
      print('Cart saved to Firestore: \\${_items.length} items');
    } catch (e) {
      print('Error saving cart to Firestore: \\${e.toString()}');
    }
  }

  void addToCart(CartItem item) {
    // Try to find an existing item with the same productId and unit (including box)
    final index = _items.indexWhere((e) =>
      e.productId == item.productId &&
      _normalizeUnit(e.unit) == _normalizeUnit(item.unit)
    );
    if (index >= 0) {
      // Sum the amounts for compatible units
      final existing = _items[index];
      double existingAmount = _parseAmount(existing.amount, existing.unit);
      double newAmount = _parseAmount(item.amount, item.unit);
      double totalAmount = existingAmount + newAmount;
      existing.amount = _amountToString(totalAmount, existing.unit);
      existing.quantity = 1; // Always 1, since amount is summed
      existing.totalPrice = existing.unitPrice * totalAmount;
    } else {
      // For new items, set totalPrice based on amount
      double amount = _parseAmount(item.amount, item.unit);
      item.totalPrice = item.unitPrice * amount;
      item.quantity = 1;
      _items.add(item);
    }
    _saveCartToFirestore();
    notifyListeners();
  }

  // Helper to normalize units (e.g., 'kg', 'g', 'piece', 'box')
  String _normalizeUnit(String unit) {
    final u = unit.toLowerCase();
    if (u.contains('kg') || u.contains('g')) return 'kg';
    if (u.contains('piece') || u.contains('pc')) return 'piece';
    if (u.contains('box')) return 'box';
    return u;
  }

  // Helper to parse amount string to double (supports kg, g, piece, box)
  double _parseAmount(String amountStr, String unit) {
    final a = amountStr.toLowerCase();
    if (_normalizeUnit(unit) == 'kg') {
      if (a.endsWith('kg')) {
        return double.tryParse(a.replaceAll('kg', '').trim()) ?? 1;
      } else if (a.endsWith('g')) {
        return (double.tryParse(a.replaceAll('g', '').trim()) ?? 100) / 1000.0;
      }
    } else if (_normalizeUnit(unit) == 'piece') {
      final pcs = RegExp(r'(\d+)').firstMatch(a);
      return pcs != null ? double.tryParse(pcs.group(1)!) ?? 1 : 1;
    } else if (_normalizeUnit(unit) == 'box') {
      final boxes = RegExp(r'(\d+)').firstMatch(a);
      return boxes != null ? double.tryParse(boxes.group(1)!) ?? 1 : 1;
    }
    return 1;
  }

  // Helper to convert amount double back to string for display
  String _amountToString(double amount, String unit) {
    if (_normalizeUnit(unit) == 'kg') {
      return amount >= 1 ? '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}kg' : '${(amount * 1000).toStringAsFixed(0)}g';
    } else if (_normalizeUnit(unit) == 'piece') {
      return '${amount.toStringAsFixed(0)} pcs';
    } else if (_normalizeUnit(unit) == 'box') {
      return '${amount.toStringAsFixed(0)} box';
    }
    return amount.toString();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((e) => e.productId == productId);
    _saveCartToFirestore();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      // Recalculate totalPrice
      final item = _items[index];
      double singleAmount = _parseAmount(item.amount, item.unit);
      final totalAmount = singleAmount * item.quantity;
      item.totalPrice = item.unitPrice * totalAmount;
      _saveCartToFirestore();
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      _items[index].quantity += 1;
      // Recalculate totalPrice
      final item = _items[index];
      double singleAmount = _parseAmount(item.amount, item.unit);
      final totalAmount = singleAmount * item.quantity;
      item.totalPrice = item.unitPrice * totalAmount;
      _saveCartToFirestore();
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
        // Recalculate totalPrice
        final item = _items[index];
        double singleAmount = _parseAmount(item.amount, item.unit);
        final totalAmount = singleAmount * item.quantity;
        item.totalPrice = item.unitPrice * totalAmount;
      } else {
        _items.removeAt(index);
      }
      _saveCartToFirestore();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCartToFirestore();
    notifyListeners();
  }

  void clearCartOnSignOut() {
    _items.clear();
    notifyListeners();
  }

  double getTotal() {
    return items.fold(0.0, (sum, item) => sum + (item.totalPrice ?? 0.0));
  }
} 