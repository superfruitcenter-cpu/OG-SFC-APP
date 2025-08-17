import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_repository.dart';
import '../services/messaging_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  final MessagingService _messagingService = MessagingService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  String? get fcmToken => _messagingService.fcmToken;
  bool get isInitialized => _messagingService.isInitialized;

  /// Initialize the notification provider
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Initialize messaging service
      await _messagingService.initialize();

      // Listen to notifications
      _repository.getUserNotifications().listen((notifications) {
        _notifications = notifications;
        notifyListeners();
      });

      // Listen to unread count
      _repository.getUnreadNotificationsCount().listen((count) {
        _unreadCount = count;
        notifyListeners();
      });

      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
      _setLoading(false);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      _clearError();
      await _repository.markAsRead(notificationId);
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _clearError();
      await _repository.markAllAsRead();
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _clearError();
      await _repository.deleteNotification(notificationId);
    } catch (e) {
      _setError('Failed to delete notification: $e');
    }
  }

  /// Delete old notifications
  Future<void> deleteOldNotifications() async {
    try {
      _clearError();
      await _repository.deleteOldNotifications();
    } catch (e) {
      _setError('Failed to delete old notifications: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      _clearError();
      await _messagingService.subscribeToTopic(topic);
    } catch (e) {
      _setError('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      _clearError();
      await _messagingService.unsubscribeFromTopic(topic);
    } catch (e) {
      _setError('Failed to unsubscribe from topic: $e');
    }
  }

  /// Update user token (call when user logs in)
  Future<void> updateUserToken() async {
    try {
      _clearError();
      await _messagingService.updateUserToken();
    } catch (e) {
      _setError('Failed to update user token: $e');
    }
  }

  /// Clear user token (call when user logs out)
  Future<void> clearUserToken() async {
    try {
      _clearError();
      await _messagingService.clearUserToken();
    } catch (e) {
      _setError('Failed to clear user token: $e');
    }
  }

  /// Get notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      _clearError();
      return await _repository.getNotificationById(notificationId);
    } catch (e) {
      _setError('Failed to get notification: $e');
      return null;
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    try {
      _setLoading(true);
      _clearError();
      
      // The stream will automatically update the notifications
      await Future.delayed(const Duration(milliseconds: 500));
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to refresh notifications: $e');
      _setLoading(false);
    }
  }

  /// Clear error
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((notification) => notification.type == type).toList();
  }

  /// Get read notifications
  List<NotificationModel> get readNotifications {
    return _notifications.where((notification) => notification.isRead).toList();
  }

  /// Get unread notifications
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  /// Check if there are any notifications
  bool get hasNotifications => _notifications.isNotEmpty;

  /// Get latest notification
  NotificationModel? get latestNotification {
    return _notifications.isNotEmpty ? _notifications.first : null;
  }

  @override
  void dispose() {
    _messagingService.dispose();
    super.dispose();
  }
} 