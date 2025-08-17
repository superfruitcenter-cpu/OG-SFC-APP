class CartItem {
  final String productId;
  final String name;
  final String price; // String, as per your product model
  final List<String> imageUrls;
  int quantity;
  String amount; // e.g., '100g', '1kg', '1pc'
  final String unit;   // e.g., 'kg', 'piece'
  double unitPrice; // e.g., 40.0
  String unitPriceDisplay; // e.g., '₹40/kg'
  double totalPrice; // e.g., 400.0

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrls,
    required this.quantity,
    required this.amount,
    required this.unit,
    required this.unitPrice,
    required this.unitPriceDisplay,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      name: json['name'],
      price: json['price'],
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      quantity: json['quantity'],
      amount: json['amount'] ?? '',
      unit: json['unit'] ?? '',
      unitPrice: (json['unitPrice'] is int) ? (json['unitPrice'] as int).toDouble() : (json['unitPrice'] ?? 0.0),
      unitPriceDisplay: json['unitPriceDisplay'] ?? '',
      totalPrice: (json['totalPrice'] is int) ? (json['totalPrice'] as int).toDouble() : (json['totalPrice'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrls': imageUrls,
      'quantity': quantity,
      'amount': amount,
      'unit': unit,
      'unitPrice': unitPrice,
      'unitPriceDisplay': unitPriceDisplay,
      'totalPrice': totalPrice,
    };
  }
} 