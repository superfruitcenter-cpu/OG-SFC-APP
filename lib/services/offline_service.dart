import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class OfflineService extends ChangeNotifier {
  static const String _productsBox = 'products';
  static const String _cartBox = 'cart';
  static const String _ordersBox = 'orders';
  static const String _userDataBox = 'user_data';
  static const String _syncQueueBox = 'sync_queue';

  late Box _productsBoxInstance;
  late Box _cartBoxInstance;
  late Box _ordersBoxInstance;
  late Box _userDataBoxInstance;
  late Box _syncQueueBoxInstance;

  bool _isOnline = true;
  bool _isInitialized = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  // Singleton pattern
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);

      // Open Hive boxes
      _productsBoxInstance = await Hive.openBox(_productsBox);
      _cartBoxInstance = await Hive.openBox(_cartBox);
      _ordersBoxInstance = await Hive.openBox(_ordersBox);
      _userDataBoxInstance = await Hive.openBox(_userDataBox);
      _syncQueueBoxInstance = await Hive.openBox(_syncQueueBox);

      // Start connectivity monitoring
      await _startConnectivityMonitoring();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing OfflineService: $e');
      rethrow;
    }
  }

  Future<void> _startConnectivityMonitoring() async {
    // Get initial connectivity status
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(connectivityResult);

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_updateConnectivityStatus);
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (wasOnline != _isOnline) {
      notifyListeners();
      
      if (_isOnline) {
        _syncOfflineData();
      }
    }
  }

  // Product caching methods
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    try {
      await _productsBoxInstance.clear();
      for (final product in products) {
        await _productsBoxInstance.put(product['id'], jsonEncode(product));
      }
    } catch (e) {
      debugPrint('Error caching products: $e');
    }
  }

  List<Map<String, dynamic>> getCachedProducts() {
    try {
      final products = <Map<String, dynamic>>[];
      for (final key in _productsBoxInstance.keys) {
        final productData = _productsBoxInstance.get(key);
        if (productData != null) {
          products.add(jsonDecode(productData));
        }
      }
      return products;
    } catch (e) {
      debugPrint('Error getting cached products: $e');
      return [];
    }
  }

  // Cart caching methods
  Future<void> cacheCartItems(List<Map<String, dynamic>> cartItems) async {
    try {
      await _cartBoxInstance.clear();
      for (final item in cartItems) {
        await _cartBoxInstance.put(item['id'], jsonEncode(item));
      }
    } catch (e) {
      debugPrint('Error caching cart items: $e');
    }
  }

  List<Map<String, dynamic>> getCachedCartItems() {
    try {
      final cartItems = <Map<String, dynamic>>[];
      for (final key in _cartBoxInstance.keys) {
        final itemData = _cartBoxInstance.get(key);
        if (itemData != null) {
          cartItems.add(jsonDecode(itemData));
        }
      }
      return cartItems;
    } catch (e) {
      debugPrint('Error getting cached cart items: $e');
      return [];
    }
  }

  // Order caching methods
  Future<void> cacheOrders(List<Map<String, dynamic>> orders) async {
    try {
      await _ordersBoxInstance.clear();
      for (final order in orders) {
        await _ordersBoxInstance.put(order['id'], jsonEncode(order));
      }
    } catch (e) {
      debugPrint('Error caching orders: $e');
    }
  }

  List<Map<String, dynamic>> getCachedOrders() {
    try {
      final orders = <Map<String, dynamic>>[];
      for (final key in _ordersBoxInstance.keys) {
        final orderData = _ordersBoxInstance.get(key);
        if (orderData != null) {
          orders.add(jsonDecode(orderData));
        }
      }
      return orders;
    } catch (e) {
      debugPrint('Error getting cached orders: $e');
      return [];
    }
  }

  // User data caching
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      await _userDataBoxInstance.put('current_user', jsonEncode(userData));
    } catch (e) {
      debugPrint('Error caching user data: $e');
    }
  }

  Map<String, dynamic>? getCachedUserData() {
    try {
      final userData = _userDataBoxInstance.get('current_user');
      if (userData != null) {
        return jsonDecode(userData);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached user data: $e');
      return null;
    }
  }

  // Sync queue management
  Future<void> addToSyncQueue(String action, Map<String, dynamic> data) async {
    try {
      final syncItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'action': action,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };
      await _syncQueueBoxInstance.put(syncItem['id'], jsonEncode(syncItem));
    } catch (e) {
      debugPrint('Error adding to sync queue: $e');
    }
  }

  List<Map<String, dynamic>> getSyncQueue() {
    try {
      final queue = <Map<String, dynamic>>[];
      for (final key in _syncQueueBoxInstance.keys) {
        final itemData = _syncQueueBoxInstance.get(key);
        if (itemData != null) {
          queue.add(jsonDecode(itemData));
        }
      }
      return queue;
    } catch (e) {
      debugPrint('Error getting sync queue: $e');
      return [];
    }
  }

  Future<void> removeFromSyncQueue(String id) async {
    try {
      await _syncQueueBoxInstance.delete(id);
    } catch (e) {
      debugPrint('Error removing from sync queue: $e');
    }
  }

  // Sync offline data when connection is restored
  Future<void> _syncOfflineData() async {
    if (!_isOnline) return;

    try {
      final syncQueue = getSyncQueue();
      for (final item in syncQueue) {
        await _processSyncItem(item);
      }
    } catch (e) {
      debugPrint('Error syncing offline data: $e');
    }
  }

  Future<void> _processSyncItem(Map<String, dynamic> item) async {
    try {
      final action = item['action'] as String;
      final data = item['data'] as Map<String, dynamic>;
      final retryCount = item['retryCount'] as int;

      // Process different sync actions
      switch (action) {
        case 'add_to_cart':
          // Sync cart item to server
          await _syncCartItem(data);
          break;
        case 'update_cart':
          // Sync cart update to server
          await _syncCartUpdate(data);
          break;
        case 'place_order':
          // Sync order to server
          await _syncOrder(data);
          break;
        case 'update_profile':
          // Sync profile update to server
          await _syncProfileUpdate(data);
          break;
      }

      // Remove from sync queue if successful
      await removeFromSyncQueue(item['id']);
    } catch (e) {
      debugPrint('Error processing sync item: $e');
      
      // Increment retry count
      final newRetryCount = (item['retryCount'] as int) + 1;
      if (newRetryCount < 3) {
        item['retryCount'] = newRetryCount;
        await _syncQueueBoxInstance.put(item['id'], jsonEncode(item));
      } else {
        // Remove from queue after 3 retries
        await removeFromSyncQueue(item['id']);
      }
    }
  }

  // Sync methods for different actions
  Future<void> _syncCartItem(Map<String, dynamic> data) async {
    // TODO: Implement actual API call to sync cart item
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _syncCartUpdate(Map<String, dynamic> data) async {
    // TODO: Implement actual API call to sync cart update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _syncOrder(Map<String, dynamic> data) async {
    // TODO: Implement actual API call to sync order
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _syncProfileUpdate(Map<String, dynamic> data) async {
    // TODO: Implement actual API call to sync profile update
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Clear all cached data
  Future<void> clearAllCachedData() async {
    try {
      await _productsBoxInstance.clear();
      await _cartBoxInstance.clear();
      await _ordersBoxInstance.clear();
      await _userDataBoxInstance.clear();
      await _syncQueueBoxInstance.clear();
    } catch (e) {
      debugPrint('Error clearing cached data: $e');
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
} 