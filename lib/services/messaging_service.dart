import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  debugPrint('Handling a background message: \\${message.messageId}');
  // Do NOT show a local notification here. Let the system handle background notifications.
}

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize the messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      await _requestNotificationPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      await _setupMessageHandlers();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      debugPrint('MessagingService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing MessagingService: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');
      
      // If permission is denied, show a dialog to guide user to settings
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notification permission denied');
      } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notification permission granted');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Save token to local storage
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
        debugPrint('FCM Token refreshed: $newToken');
      });

      // Save token to Firestore if user is logged in
      if (_auth.currentUser != null && _fcmToken != null) {
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcm_token': token,
          'last_token_update': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved to Firestore for user: ${user.uid}');
        debugPrint('FCM token: $token');
      } else {
        debugPrint('No current user found when saving FCM token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  /// Set up message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message);
    });

    // Check if app was opened from notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      final data = message.data;

      // Use data fields if notification is null (for data-only FCM messages)
      final title = notification?.title ?? data['title'] ?? '';
      final body = notification?.body ?? data['body'] ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        await _localNotifications.show(
          notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              icon: '@mipmap/ic_launcher',
              color: const Color(0xFF4CAF50),
              enableLights: true,
              enableVibration: true,
              playSound: true,
              actions: <AndroidNotificationAction>[
                const AndroidNotificationAction('id_1', 'View'),
                const AndroidNotificationAction('id_2', 'Dismiss'),
              ],
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: json.encode(message.data),
        );
        debugPrint('Local notification shown successfully');
      }
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to appropriate screen based on notification type
    if (message.data['type'] == 'order_update') {
      // Navigate to order details
      // You'll need to implement this navigation
    } else if (message.data['type'] == 'new_product') {
      // Navigate to product details
      // You'll need to implement this navigation
    }
  }

  /// Handle notification tap from local notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        // Handle navigation based on notification type
        if (data['type'] == 'order_update') {
          // Navigate to order details
        } else if (data['type'] == 'new_product') {
          // Navigate to product details
        }
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
      }
    }
  }

  /// Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Update user's FCM token when they log in
  Future<void> updateUserToken() async {
    if (_auth.currentUser != null && _fcmToken != null) {
      await _saveTokenToFirestore(_fcmToken!);
    }
  }

  /// Clear FCM token when user logs out
  Future<void> clearUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcm_token': null,
          'last_token_update': FieldValue.serverTimestamp(),
        });
      }
      
      // Clear local token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      _fcmToken = null;
      
      debugPrint('FCM token cleared');
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }

  /// Get stored FCM token from local storage
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('Error getting stored FCM token: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
} 