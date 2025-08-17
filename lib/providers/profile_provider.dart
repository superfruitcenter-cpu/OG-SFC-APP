import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider with ChangeNotifier {
  bool _loading = true;
  String? _userId;
  String? _name;
  String? _email;
  String? _phone;
  int _avatar = 0;

  bool get loading => _loading;
  String? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  String? get phone => _phone;
  int get avatar => _avatar;

  ProfileProvider() {
    loadProfile();
  }

  Future<void> loadProfile() async {
    _loading = true;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    await user.reload();
    _userId = user.uid;
    _email = user.email;
    _phone = user.phoneNumber;
    // Fetch Firestore user profile
    final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _name = (data['name'] ?? '').toString().trim();
      final avatarValue = data['avatar'] ?? 0;
      if (avatarValue is int && avatarValue >= 0 && avatarValue <= 11) {
        _avatar = avatarValue;
      } else {
        _avatar = 0;
      }
      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user_name', _name ?? '');
      prefs.setInt('user_avatar', _avatar);
    }
    _loading = false;
    notifyListeners();
  }

  // Optionally, add methods to update profile fields and reload
  Future<void> refresh() async {
    await loadProfile();
  }
} 