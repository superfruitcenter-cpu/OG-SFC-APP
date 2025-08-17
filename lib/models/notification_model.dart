import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderUpdate,
  newProduct,
  promotion,
  delivery,
  payment,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final String? userId;
  final bool isRead;
  final DateTime createdAt;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    this.userId,
    this.isRead = false,
    required this.createdAt,
    this.imageUrl,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: _parseNotificationType(data['type']),
      data: data['data'] ?? {},
      userId: data['user_id'],
      isRead: data['is_read'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['image_url'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'data': data,
      'user_id': userId,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
      'image_url': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    String? userId,
    bool? isRead,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      userId: userId ?? this.userId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'new_product':
        return NotificationType.newProduct;
      case 'promotion':
        return NotificationType.promotion;
      case 'delivery':
        return NotificationType.delivery;
      case 'payment':
        return NotificationType.payment;
      default:
        return NotificationType.general;
    }
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.orderUpdate:
        return 'Order Update';
      case NotificationType.newProduct:
        return 'New Product';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.delivery:
        return 'Delivery';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.general:
        return 'General';
    }
  }

  String get typeIcon {
    switch (type) {
      case NotificationType.orderUpdate:
        return '📦';
      case NotificationType.newProduct:
        return '🍎';
      case NotificationType.promotion:
        return '🎉';
      case NotificationType.delivery:
        return '🚚';
      case NotificationType.payment:
        return '💳';
      case NotificationType.general:
        return '📢';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
} 