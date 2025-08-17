import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String price;
  final int stock;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> nutrition;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.nutrition,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] is String ? data['price'] : data['price'].toString(),
      stock: data['stock'] ?? 0,
      imageUrls: (data['image_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? (data['created_at'] as Timestamp).toDate(),
      nutrition: data['nutrition'] != null ? Map<String, String>.from(data['nutrition']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image_urls': imageUrls,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'nutrition': nutrition,
    };
  }
} 