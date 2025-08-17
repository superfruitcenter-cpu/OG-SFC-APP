import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_service.dart';

class OfflineUtils {
  // Check if the app is currently offline
  static bool isOffline(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    return !offlineService.isOnline;
  }

  // Check if offline service is initialized
  static bool isInitialized(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    return offlineService.isInitialized;
  }

  // Get offline status with listener
  static bool isOfflineWithListener(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context);
    return !offlineService.isOnline;
  }

  // Show offline snackbar
  static void showOfflineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('You\'re offline. Some features may not be available.'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show online snackbar
  static void showOnlineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 8),
            Text('You\'re back online!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show sync progress dialog
  static void showSyncProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Syncing offline data...'),
          ],
        ),
      ),
    );
  }

  // Hide sync progress dialog
  static void hideSyncProgressDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Show offline mode dialog
  static void showOfflineModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Mode'),
        content: const Text(
          'You\'re currently offline. Some features may not be available. '
          'Your data will be synced when you\'re back online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Check if feature is available offline
  static bool isFeatureAvailableOffline(String feature) {
    const offlineFeatures = [
      'browse_products',
      'view_cart',
      'view_orders',
      'view_profile',
      'search_products',
    ];

    return offlineFeatures.contains(feature);
  }

  // Get offline feature message
  static String getOfflineFeatureMessage(String feature) {
    switch (feature) {
      case 'add_to_cart':
        return 'You can add items to cart, but they will be synced when online.';
      case 'place_order':
        return 'Orders can be placed offline and will be processed when online.';
      case 'update_profile':
        return 'Profile updates will be synced when you\'re back online.';
      case 'search_products':
        return 'Search is available with cached products.';
      default:
        return 'This feature is available offline.';
    }
  }

  // Format offline timestamp
  static String formatOfflineTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Get offline data size
  static String formatDataSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Validate offline data
  static bool isValidOfflineData(Map<String, dynamic> data) {
    try {
      // Check if required fields exist
      if (data['id'] == null) return false;
      if (data['timestamp'] == null) return false;

      // Validate timestamp
      final timestamp = DateTime.parse(data['timestamp']);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      // Data is valid if it's less than 7 days old
      return difference.inDays < 7;
    } catch (e) {
      return false;
    }
  }

  // Clean expired offline data
  static List<Map<String, dynamic>> cleanExpiredData(
    List<Map<String, dynamic>> dataList,
  ) {
    final now = DateTime.now();
    return dataList.where((data) {
      try {
        final timestamp = DateTime.parse(data['timestamp']);
        final difference = now.difference(timestamp);
        return difference.inDays < 7;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get offline sync status
  static String getSyncStatus(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    final syncQueue = offlineService.getSyncQueue();

    if (syncQueue.isEmpty) {
      return 'All data synced';
    } else {
      return '${syncQueue.length} items pending sync';
    }
  }

  // Check if sync is needed
  static bool isSyncNeeded(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    final syncQueue = offlineService.getSyncQueue();
    return syncQueue.isNotEmpty;
  }

  // Get offline storage info
  static Map<String, dynamic> getOfflineStorageInfo(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    
    final products = offlineService.getCachedProducts();
    final cartItems = offlineService.getCachedCartItems();
    final orders = offlineService.getCachedOrders();
    final syncQueue = offlineService.getSyncQueue();

    return {
      'products_count': products.length,
      'cart_items_count': cartItems.length,
      'orders_count': orders.length,
      'sync_queue_count': syncQueue.length,
      'total_items': products.length + cartItems.length + orders.length + syncQueue.length,
    };
  }

  // Clear all offline data
  static Future<void> clearAllOfflineData(BuildContext context) async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    await offlineService.clearAllCachedData();
  }

  // Export offline data
  static Map<String, dynamic> exportOfflineData(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    
    return {
      'products': offlineService.getCachedProducts(),
      'cart_items': offlineService.getCachedCartItems(),
      'orders': offlineService.getCachedOrders(),
      'user_data': offlineService.getCachedUserData(),
      'sync_queue': offlineService.getSyncQueue(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Import offline data
  static Future<void> importOfflineData(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final offlineService = Provider.of<OfflineService>(context, listen: false);
    
    if (data['products'] != null) {
      await offlineService.cacheProducts(List<Map<String, dynamic>>.from(data['products']));
    }
    
    if (data['cart_items'] != null) {
      await offlineService.cacheCartItems(List<Map<String, dynamic>>.from(data['cart_items']));
    }
    
    if (data['orders'] != null) {
      await offlineService.cacheOrders(List<Map<String, dynamic>>.from(data['orders']));
    }
    
    if (data['user_data'] != null) {
      await offlineService.cacheUserData(Map<String, dynamic>.from(data['user_data']));
    }
  }
} 