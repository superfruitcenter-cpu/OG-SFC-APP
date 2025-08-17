import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: user.uid)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: user.uid)
          .where('is_read', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'is_read': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Create notification (for admin use)
  Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    required Map<String, dynamic> data,
    String? userId,
    String? imageUrl,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        title: title,
        body: body,
        type: type,
        data: data,
        userId: userId,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Send notification to all users (for admin use)
  Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    required NotificationType type,
    required Map<String, dynamic> data,
    String? imageUrl,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notification = NotificationModel(
          id: '',
          title: title,
          body: body,
          type: type,
          data: data,
          userId: userDoc.id,
          createdAt: DateTime.now(),
          imageUrl: imageUrl,
        );

        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, notification.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send notification to all users: $e');
    }
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required Map<String, dynamic> data,
    String? imageUrl,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        title: title,
        body: body,
        type: type,
        data: data,
        userId: userId,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      throw Exception('Failed to send notification to user: $e');
    }
  }

  /// Get notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        return NotificationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get notification: $e');
    }
  }

  /// Delete old notifications (older than 30 days)
  Future<void> deleteOldNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: user.uid)
          .where('created_at', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old notifications: $e');
    }
  }
} 