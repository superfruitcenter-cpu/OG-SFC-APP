import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fruit_store_user_app/services/cart_service.dart';
import 'package:fruit_store_user_app/models/cart_item.dart';
import 'package:fruit_store_user_app/utils/responsive_utils.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  // Map backend status to user-friendly status
  String getUserOrderStatus(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'ordered':
        return 'ordered';
      case 'packed':
        return 'packed';
      case 'out for delivery':
        return 'out for delivery';
      case 'delivered':
        return 'delivered';
      default:
        return 'ordered';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>;
    final address = order['address'] as Map<String, dynamic>;
    // Safely parse totalAmount
    final totalAmount = order['total_amount'] is int
        ? (order['total_amount'] as int).toDouble()
        : order['total_amount'] is double
            ? order['total_amount'] as double
            : double.tryParse(order['total_amount'].toString()) ?? 0.0;
    final paymentStatus = order['payment_status'] as String;
    final userStatus = getUserOrderStatus(paymentStatus);
    final createdAt = order['created_at'] as Timestamp;
    final deliveryFee = order['delivery_fee'] is int
        ? (order['delivery_fee'] as int).toDouble()
        : order['delivery_fee'] is double
            ? order['delivery_fee'] as double
            : double.tryParse(order['delivery_fee']?.toString() ?? '') ?? 0.0;
    final processingFee = order['processing_fee'] is int
        ? (order['processing_fee'] as int).toDouble()
        : order['processing_fee'] is double
            ? order['processing_fee'] as double
            : double.tryParse(order['processing_fee']?.toString() ?? '') ?? 0.0;
    double productTotal = 0;
    for (var item in items) {
      if (item['totalPrice'] != null && (item['totalPrice'] is num ? item['totalPrice'] > 0 : double.tryParse(item['totalPrice'].toString()) != null)) {
        productTotal += item['totalPrice'] is num ? (item['totalPrice'] as num).toDouble() : double.tryParse(item['totalPrice'].toString()) ?? 0.0;
      } else {
        String displayPrice = item['displayPrice']?.toString() ?? '';
        if (displayPrice.contains('/')) {
          displayPrice = displayPrice.split('/')[0];
        }
        final priceNum = double.tryParse(displayPrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        final quantity = (item['quantity'] is int) ? item['quantity'] as int : int.tryParse(item['quantity'].toString()) ?? 1;
        productTotal += priceNum * quantity;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: TextStyle(
            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: ResponsiveUtils.responsiveIconSize(context),
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show Order ID
            Row(
              children: [
                Text(
                  'Order ID: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                  ),
                ),
                SelectableText(
                  order['id'] != null ? order['id'].toString() : '-',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
            // Order Tracking Progress Bar
            _OrderTrackingBar(
              status: userStatus,
            ),
            // Order Status Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveBorderRadius(context),
                ),
              ),
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Status',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12),
                            vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 6),
                          ),
                          decoration: BoxDecoration(
                            color: userStatus == 'delivered'
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 20),
                            ),
                          ),
                          child: Text(
                            userStatus.toUpperCase(),
                            style: TextStyle(
                              color: userStatus == 'delivered'
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                    Text(
                      'Ordered on: ${createdAt.toDate().toString().substring(0, 16)}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),

            // Delivery Address Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveBorderRadius(context),
                ),
              ),
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                    Text(
                      address['name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
                    Text(
                      '${address['flatNo'] ?? ''}${(address['flatNo'] != null && address['buildingName'] != null) ? ', ' : ''}${address['buildingName'] ?? ''}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                      ),
                    ),
                    if ((address['landmark'] ?? '').toString().isNotEmpty)
                      Text(
                        'Landmark: ${address['landmark']}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                        ),
                      ),
                    if ((address['phone'] ?? '').toString().isNotEmpty)
                      Text(
                        'Phone: ${address['phone']}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),

            // Order Items Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.responsiveBorderRadius(context),
                ),
              ),
              child: Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                    ...items.map((item) {
                      final name = item['name']?.toString() ?? '';
                      final amount = item['amount']?.toString() ?? '';
                      final unit = item['unit']?.toString() ?? '';
                      final unitPriceDisplay = item['unitPriceDisplay']?.toString() ?? (item['displayPrice']?.toString() ?? item['price']?.toString() ?? '');
                      final numericPrice = item['numericPrice'] is num ? (item['numericPrice'] as num).toDouble() : double.tryParse(item['numericPrice']?.toString() ?? '');
                      // Calculate price
                      double? totalPrice = item['totalPrice'] is num ? (item['totalPrice'] as num).toDouble() : double.tryParse(item['totalPrice']?.toString() ?? '');
                      if (totalPrice == null || totalPrice == 0.0) {
                        // Try to parse amount and multiply by numericPrice
                        double parsedAmount = 1;
                        final amt = amount.toLowerCase();
                      if (unit == 'kg') {
                          if (amt.endsWith('kg')) {
                            parsedAmount = double.tryParse(amt.replaceAll('kg', '').trim()) ?? 1;
                          } else if (amt.endsWith('g')) {
                            parsedAmount = (double.tryParse(amt.replaceAll('g', '').trim()) ?? 100) / 1000.0;
                          }
                        } else if (unit == 'piece' || unit == 'pc') {
                          final pcs = RegExp(r'(\d+)').firstMatch(amt);
                          parsedAmount = pcs != null ? double.tryParse(pcs.group(1)!) ?? 1 : 1;
                        } else if (unit == 'box') {
                          final boxes = RegExp(r'(\d+)').firstMatch(amt);
                          parsedAmount = boxes != null ? double.tryParse(boxes.group(1)!) ?? 1 : 1;
                        }
                        if (numericPrice != null && numericPrice > 0) {
                          totalPrice = numericPrice * parsedAmount;
                        } else if (item['displayPrice'] != null) {
                          final priceMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(item['displayPrice'].toString());
                          if (priceMatch != null) {
                            totalPrice = (double.tryParse(priceMatch.group(1)!) ?? 0) * parsedAmount;
                          }
                        }
                      }
                      // Title: name (amount, unitPriceDisplay)
                      String title = name;
                      if (amount.isNotEmpty && unitPriceDisplay.isNotEmpty) {
                        title = '$name ($amount, $unitPriceDisplay)';
                      } else if (amount.isNotEmpty) {
                        title = '$name ($amount)';
                      } else if (unitPriceDisplay.isNotEmpty) {
                        title = '$name ($unitPriceDisplay)';
                      }
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                ),
                              ),
                            ),
                            (totalPrice != null && totalPrice > 0)
                              ? Text(
                                  '₹${totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                  ),
                                )
                              : const SizedBox(),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    // Show product total, delivery fee, and grand total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Product Total',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                          ),
                        ),
                        Text(
                          '₹' + productTotal.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Fee',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                          ),
                        ),
                        Text(
                          '₹' + deliveryFee.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                          ),
                        ),
                      ],
                    ),
                    if (processingFee > 0) ...[
                      SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Processing Fee',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                            ),
                          ),
                          Text(
                            '₹' + processingFee.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                          ),
                        ),
                        Text(
                          '₹' + (productTotal + deliveryFee + processingFee).toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18),
                          ),
                        ),
                      ],
                    ),
                    // Reorder Button
                    if (paymentStatus == 'delivered' || paymentStatus == 'failed')
                      Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.shopping_cart,
                              size: ResponsiveUtils.responsiveIconSize(context),
                            ),
                            label: Text(
                              'Reorder',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: ResponsiveUtils.responsivePadding(
                                context,
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.responsiveBorderRadius(context),
                                ),
                              ),
                            ),
                            onPressed: () async {
                              final cart = Provider.of<CartService>(context, listen: false);
                              for (var item in items) {
                                // Get image URLs
                                List<String> imageUrls = [];
                                if (item['imageUrls'] != null && (item['imageUrls'] as List).isNotEmpty) {
                                  imageUrls = List<String>.from(item['imageUrls']);
                                } else if (item['imageUrl'] != null) {
                                  imageUrls = [item['imageUrl']];
                                } else if (item['image_url'] != null) {
                                  imageUrls = [item['image_url']];
                                }
                                
                                // If no image URLs and we have product_id, try to fetch from Firestore
                                if (imageUrls.isEmpty && item['product_id'] != null && item['product_id'].toString().isNotEmpty) {
                                  try {
                                    final doc = await FirebaseFirestore.instance.collection('products').doc(item['product_id']).get();
                                    if (doc.exists) {
                                      final data = doc.data();
                                      if (data != null && data['image_url'] != null) {
                                        final firestoreImageUrls = data['image_url'] as List<dynamic>;
                                        if (firestoreImageUrls.isNotEmpty) {
                                          imageUrls = firestoreImageUrls.map((e) => e.toString()).toList();
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    print('Error fetching product images: $e');
                                  }
                                }
                                
                                // Get price - use unitPriceDisplay if available, otherwise extract from displayPrice
                                String price = '';
                                if (item['unitPriceDisplay'] != null && item['unitPriceDisplay'].toString().isNotEmpty) {
                                  price = item['unitPriceDisplay'].toString();
                                } else if (item['displayPrice'] != null && item['displayPrice'].toString().isNotEmpty) {
                                  price = item['displayPrice'].toString();
                                } else {
                                  // Fallback: create price string from unitPrice
                                  final unitPrice = item['unitPrice'] is num ? (item['unitPrice'] as num).toDouble() : double.tryParse(item['unitPrice']?.toString() ?? '') ?? 0.0;
                                  final unit = item['unit']?.toString() ?? '';
                                  price = '₹${unitPrice.toStringAsFixed(0)}/$unit';
                                }
                                
                                // Get unit price as number
                                double unitPrice = 0.0;
                                if (item['unitPrice'] is num) {
                                  unitPrice = (item['unitPrice'] as num).toDouble();
                                } else if (item['unitPrice'] != null) {
                                  unitPrice = double.tryParse(item['unitPrice'].toString()) ?? 0.0;
                                } else {
                                  // Extract from price string
                                  final priceMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(price);
                                  if (priceMatch != null) {
                                    unitPrice = double.tryParse(priceMatch.group(1)!) ?? 0.0;
                                  }
                                }
                                
                                // Get total price
                                double totalPrice = 0.0;
                                if (item['totalPrice'] is num) {
                                  totalPrice = (item['totalPrice'] as num).toDouble();
                                } else if (item['totalPrice'] != null) {
                                  totalPrice = double.tryParse(item['totalPrice'].toString()) ?? 0.0;
                                } else {
                                  // Calculate from amount and unit price
                                  final amount = item['amount']?.toString() ?? '';
                                  final unit = item['unit']?.toString() ?? '';
                                  final quantity = item['quantity'] ?? 1;
                                  
                                  double parsedAmount = 1;
                                  final amt = amount.toLowerCase();
                                  if (unit == 'kg') {
                                    if (amt.endsWith('kg')) {
                                      parsedAmount = double.tryParse(amt.replaceAll('kg', '').trim()) ?? 1;
                                    } else if (amt.endsWith('g')) {
                                      parsedAmount = (double.tryParse(amt.replaceAll('g', '').trim()) ?? 100) / 1000.0;
                                    }
                                  } else if (unit == 'piece' || unit == 'pc') {
                                    final pcs = RegExp(r'(\d+)').firstMatch(amt);
                                    parsedAmount = pcs != null ? double.tryParse(pcs.group(1)!) ?? 1 : 1;
                                  } else if (unit == 'box') {
                                    final boxes = RegExp(r'(\d+)').firstMatch(amt);
                                    parsedAmount = boxes != null ? double.tryParse(boxes.group(1)!) ?? 1 : 1;
                                  }
                                  
                                  totalPrice = unitPrice * parsedAmount * quantity;
                                }
                                
                                // Calculate total amount (amount × quantity) for reorder
                                final originalQuantity = item['quantity'] ?? 1;
                                final originalAmount = item['amount']?.toString() ?? '';
                                final unit = item['unit']?.toString() ?? '';
                                
                                // Parse the original amount
                                double parsedOriginalAmount = 1;
                                final amt = originalAmount.toLowerCase();
                                if (unit == 'kg') {
                                  if (amt.endsWith('kg')) {
                                    parsedOriginalAmount = double.tryParse(amt.replaceAll('kg', '').trim()) ?? 1;
                                  } else if (amt.endsWith('g')) {
                                    parsedOriginalAmount = (double.tryParse(amt.replaceAll('g', '').trim()) ?? 100) / 1000.0;
                                  }
                                } else if (unit == 'piece' || unit == 'pc') {
                                  final pcs = RegExp(r'(\d+)').firstMatch(amt);
                                  parsedOriginalAmount = pcs != null ? double.tryParse(pcs.group(1)!) ?? 1 : 1;
                                } else if (unit == 'box') {
                                  final boxes = RegExp(r'(\d+)').firstMatch(amt);
                                  parsedOriginalAmount = boxes != null ? double.tryParse(boxes.group(1)!) ?? 1 : 1;
                                }
                                
                                // Calculate total amount (original amount × quantity)
                                final totalAmountValue = parsedOriginalAmount * originalQuantity;
                                
                                // Format total amount string
                                String totalAmountStr = '';
                                if (unit == 'kg') {
                                  totalAmountStr = totalAmountValue >= 1 ? '${totalAmountValue.toStringAsFixed(totalAmountValue.truncateToDouble() == totalAmountValue ? 0 : 2)}kg' : '${(totalAmountValue * 1000).toStringAsFixed(0)}g';
                                } else if (unit == 'piece' || unit == 'pc') {
                                  totalAmountStr = '${totalAmountValue.toStringAsFixed(0)} pcs';
                                } else if (unit == 'box') {
                                  totalAmountStr = '${totalAmountValue.toStringAsFixed(0)} box';
                                } else {
                                  totalAmountStr = totalAmountValue.toString();
                                }
                                
                                cart.addToCart(
                                  CartItem(
                                    productId: item['product_id']?.toString() ?? '',
                                    name: item['name']?.toString() ?? '',
                                    price: price,
                                    imageUrls: imageUrls,
                                    quantity: 1, // Always 1 since we're adding total amount
                                    amount: totalAmountStr, // Use total amount (amount × quantity)
                                    unit: item['unit']?.toString() ?? '',
                                    unitPrice: unitPrice,
                                    unitPriceDisplay: item['unitPriceDisplay']?.toString() ?? price,
                                    totalPrice: totalPrice,
                                  ),
                                );
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: ResponsiveUtils.responsiveIconSize(context),
                                      ),
                                      SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                      Expanded(
                                        child: Text(
                                          'Reorder successful! Items added to your cart.',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green[600],
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12),
                                    ),
                                  ),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24),
                                    vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTrackingBar extends StatelessWidget {
  final String status;
  const _OrderTrackingBar({required this.status});

  int get currentStep {
    switch (status.toLowerCase()) {
      case 'ordered':
        return 1;
      case 'packed':
        return 2;
      case 'out for delivery':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Ordered',
      'Packed',
      'Out for Delivery',
      'Delivered',
    ];
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index < currentStep;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12),
                  backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                  child: Icon(
                    isActive ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: ResponsiveUtils.responsiveIconSize(context, baseSize: 14),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 10),
                    color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (index < steps.length - 1)
                  Container(
                    height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
                    width: double.infinity,
                    color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                    margin: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
} 