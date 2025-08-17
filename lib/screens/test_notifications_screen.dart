import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../utils/notification_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() => _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('FCM Token: ${provider.fcmToken ?? 'Not available'}'),
                        Text('Unread Count: ${provider.unreadCount}'),
                        Text('Total Notifications: ${provider.notifications.length}'),
                        Text('Service Initialized: ${provider.isInitialized}'),
                        if (provider.hasError)
                          Text(
                            'Error: ${provider.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendTestOrderNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Order Update Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendTestProductNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send New Product Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendTestPromotionNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Promotion Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendTestDeliveryNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Delivery Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendTestPaymentNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Payment Notification'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notification Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _markAllAsRead,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark All as Read'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _refreshNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh Notifications'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _subscribeToTopic,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: const Text('Subscribe to Promotions'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _unsubscribeFromTopic,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unsubscribe from Promotions'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestOrderNotification() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationUtils.sendOrderUpdateNotification(
          userId: user.uid,
          orderId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          orderStatus: 'Processing',
          additionalMessage: 'This is a test order update notification!',
        );
        _showSuccessMessage('Order update notification sent!');
      }
    } catch (e) {
      _showErrorMessage('Failed to send order notification: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendTestProductNotification() async {
    setState(() => _isLoading = true);
    try {
      await NotificationUtils.sendNewProductNotification(
        productName: 'Test Fresh Apples',
        productId: 'test-apple-${DateTime.now().millisecondsSinceEpoch}',
      );
      _showSuccessMessage('New product notification sent to all users!');
    } catch (e) {
      _showErrorMessage('Failed to send product notification: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendTestPromotionNotification() async {
    setState(() => _isLoading = true);
    try {
      await NotificationUtils.sendPromotionNotification(
        title: 'Special Offer! 🎉',
        message: 'Get 20% off on all fruits this weekend! Use code: FRESH20',
        promotionData: {
          'discount_percentage': 20,
          'promo_code': 'FRESH20',
          'valid_until': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        },
      );
      _showSuccessMessage('Promotion notification sent to all users!');
    } catch (e) {
      _showErrorMessage('Failed to send promotion notification: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendTestDeliveryNotification() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationUtils.sendDeliveryNotification(
          userId: user.uid,
          orderId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          deliveryStatus: 'Out for Delivery',
          estimatedTime: '30 minutes',
        );
        _showSuccessMessage('Delivery notification sent!');
      }
    } catch (e) {
      _showErrorMessage('Failed to send delivery notification: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sendTestPaymentNotification() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationUtils.sendPaymentNotification(
          userId: user.uid,
          orderId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
          paymentStatus: 'successful',
          amount: 299.99,
        );
        _showSuccessMessage('Payment notification sent!');
      }
    } catch (e) {
      _showErrorMessage('Failed to send payment notification: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isLoading = true);
    try {
      await context.read<NotificationProvider>().markAllAsRead();
      _showSuccessMessage('All notifications marked as read!');
    } catch (e) {
      _showErrorMessage('Failed to mark notifications as read: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _refreshNotifications() async {
    setState(() => _isLoading = true);
    try {
      await context.read<NotificationProvider>().refreshNotifications();
      _showSuccessMessage('Notifications refreshed!');
    } catch (e) {
      _showErrorMessage('Failed to refresh notifications: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _subscribeToTopic() async {
    setState(() => _isLoading = true);
    try {
      await context.read<NotificationProvider>().subscribeToTopic('promotions');
      _showSuccessMessage('Subscribed to promotions topic!');
    } catch (e) {
      _showErrorMessage('Failed to subscribe to topic: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _unsubscribeFromTopic() async {
    setState(() => _isLoading = true);
    try {
      await context.read<NotificationProvider>().unsubscribeFromTopic('promotions');
      _showSuccessMessage('Unsubscribed from promotions topic!');
    } catch (e) {
      _showErrorMessage('Failed to unsubscribe from topic: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 500),
      ),
    );
  }
} 