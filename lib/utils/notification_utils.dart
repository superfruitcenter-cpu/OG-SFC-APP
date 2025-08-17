import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send order update notification
  static Future<void> sendOrderUpdateNotification({
    required String userId,
    required String orderId,
    required String orderStatus,
    String? additionalMessage,
    Map<String, dynamic>? orderData, // keep for compatibility, but don't use
  }) async {
    try {
      final title = 'Order Update';
      String body;
      switch (orderStatus.toLowerCase()) {
        case 'ordered':
        case 'paid':
          body = '🎉 Your order #$orderId has been placed successfully!';
          break;
        case 'packed':
          body = '📦 Great news! Your order #$orderId has been packed and is ready to go!';
          break;
        case 'out for delivery':
          body = '🚚 Your order #$orderId is out for delivery and will reach you soon!';
          break;
        case 'delivered':
          body = '🥳 Hooray! Your order #$orderId has been delivered. Enjoy your fruits!';
          break;
        default:
          body = '🎉 Your order #$orderId has been placed successfully!';
      }
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'order_update',
        'data': {
          'order_id': orderId,
          'order_status': orderStatus,
        },
        'user_id': userId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send order update notification: $e');
    }
  }

  /// Send new product notification
  static Future<void> sendNewProductNotification({
    required String productName,
    required String productId,
    String? imageUrl,
  }) async {
    try {
      final title = 'New Product Available! 🍎';
      final body = '$productName is now available in our store!';
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': title,
          'body': body,
          'type': 'new_product',
          'data': {
            'product_id': productId,
            'product_name': productName,
          },
          'user_id': userDoc.id,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'image_url': imageUrl,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send new product notification: $e');
    }
  }

  /// Send promotion notification
  static Future<void> sendPromotionNotification({
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? promotionData,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': title,
          'body': message,
          'type': 'promotion',
          'data': promotionData ?? {},
          'user_id': userDoc.id,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'image_url': imageUrl,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send promotion notification: $e');
    }
  }

  /// Send delivery notification
  static Future<void> sendDeliveryNotification({
    required String userId,
    required String orderId,
    required String deliveryStatus,
    String? estimatedTime,
  }) async {
    try {
      final title = 'Delivery Update';
      final body = estimatedTime != null 
          ? 'Your order #$orderId is $deliveryStatus. Estimated delivery: $estimatedTime'
          : 'Your order #$orderId is $deliveryStatus';
      
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'delivery',
        'data': {
          'order_id': orderId,
          'delivery_status': deliveryStatus,
          'estimated_time': estimatedTime,
        },
        'user_id': userId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send delivery notification: $e');
    }
  }

  /// Send payment notification
  static Future<void> sendPaymentNotification({
    required String userId,
    required String orderId,
    required String paymentStatus,
    required double amount,
  }) async {
    try {
      print('Creating payment notification for user: $userId, order: $orderId'); // Debug log
      final title = 'Payment Update';
      final body = paymentStatus == 'successful' 
          ? 'Payment of ₹${amount.toStringAsFixed(2)} for order #$orderId was successful!'
          : 'Payment of ₹${amount.toStringAsFixed(2)} for order #$orderId failed. Please try again.';
      
      print('Notification title: $title'); // Debug log
      print('Notification body: $body'); // Debug log
      
      // Create notification document - this will automatically trigger the Cloud Function
      // to send a push notification via FCM
      final notificationRef = await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'payment',
        'data': {
          'order_id': orderId,
          'payment_status': paymentStatus,
          'amount': amount.toString(),
        },
        'user_id': userId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      print('Payment notification created with ID: ${notificationRef.id}'); // Debug log
      print('Payment notification created for user: $userId, order: $orderId');
    } catch (e) {
      print('Error sending payment notification: $e');
      throw Exception('Failed to send payment notification: $e');
    }
  }

  /// Send general notification to specific user
  static Future<void> sendGeneralNotification({
    required String userId,
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? data,
    bool persistent = false,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': message,
        'type': 'general',
        'data': data ?? {},
        'user_id': userId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'image_url': imageUrl,
        'persistent': persistent,
      });
    } catch (e) {
      throw Exception('Failed to send general notification: $e');
    }
  }

  /// Send general notification to all users
  static Future<void> sendGeneralNotificationToAll({
    required String title,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      final batch = _firestore.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': title,
          'body': message,
          'type': 'general',
          'data': data ?? {},
          'user_id': userDoc.id,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'image_url': imageUrl,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send general notification to all users: $e');
    }
  }

  /// Send low stock notification to admin
  static Future<void> sendLowStockNotification({
    required String productName,
    required String productId,
    required int currentStock,
    required int threshold,
  }) async {
    try {
      // Get admin users
      final adminUsersSnapshot = await _firestore
          .collection('users')
          .where('is_admin', isEqualTo: true)
          .get();
      
      final batch = _firestore.batch();
      
      for (final userDoc in adminUsersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': 'Low Stock Alert',
          'body': '$productName is running low on stock. Current stock: $currentStock (Threshold: $threshold)',
          'type': 'general',
          'data': {
            'product_id': productId,
            'product_name': productName,
            'current_stock': currentStock,
            'threshold': threshold,
          },
          'user_id': userDoc.id,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send low stock notification: $e');
    }
  }

  /// Send welcome notification to new user
  static Future<void> sendWelcomeNotification({
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'title': 'Welcome to Super Fruit Center! 🎉',
        'body': 'Hi $userName! Welcome to our fruit store. Enjoy fresh fruits delivered to your doorstep!',
        'type': 'general',
        'data': {
          'welcome_message': true,
        },
        'user_id': userId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send welcome notification: $e');
    }
  }

  /// Send test notification to debug push notifications
  static Future<void> sendTestNotification({
    required String userId,
  }) async {
    try {
      final title = 'Test Push Notification 🔔';
      final body = 'This is a test push notification to verify the system is working!';
      
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'type': 'test',
        'data': {
          'test_message': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        'user_id': userId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      
      print('Test notification created for user: $userId');
    } catch (e) {
      print('Error sending test notification: $e');
      throw Exception('Failed to send test notification: $e');
    }
  }
} 