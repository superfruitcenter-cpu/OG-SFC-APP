import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'enhanced_dashboard.dart';
import '../utils/responsive_utils.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    // Add state for loading checkout
    return _CartScreenBody(cart: cart);
  }
}

class _CartScreenBody extends StatefulWidget {
  final CartService cart;
  const _CartScreenBody({required this.cart});
  @override
  State<_CartScreenBody> createState() => _CartScreenBodyState();
}

class _CartScreenBodyState extends State<_CartScreenBody> {
  bool _isCheckingOut = false;
  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const NotificationPermissionBanner(),
          Expanded(
            child: !cart.isCartLoaded
          ? Center(child: CircularProgressIndicator())
          : (cart.items.isEmpty
          ? _buildEmptyCart()
              : _buildCartContent(context, cart)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 32)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: ResponsiveUtils.responsiveIconSize(context, baseSize: 80),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 32)),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 24),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
            Text(
              'Add some delicious fruits to get started!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 32)),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to products
                Navigator.of(context).pushReplacementNamed('/dashboard');
              },
              icon: const Icon(Icons.shopping_basket),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartService cart) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return _buildCartItem(context, item, cart, index);
              },
            ),
          ),
        ),
        _buildBottomBar(context, cart),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, dynamic item, CartService cart, int index) {
    final imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls[0] : '';
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: ValueKey(item.productId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        onDismissed: (direction) {
          final removedItem = item;
          cart.removeFromCart(item.productId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${removedItem.name} from cart'),
              duration: const Duration(milliseconds: 2000),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () {
                  cart.addToCart(item);
                },
              ),
            ),
          );
        },
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 32, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 32, color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Product Details and Controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Show amount and quantity
                      if ((item.amount ?? '').isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            String unit = item.unit ?? '';
                            String amountStr = (item.amount ?? '').toLowerCase();
                            String totalAmountStr = amountStr;
                            if (unit.contains('kg') || unit.contains('g')) {
                              // Already formatted by cart logic
                              totalAmountStr = amountStr;
                            } else if (unit.contains('piece') || unit.contains('pc')) {
                              totalAmountStr = amountStr;
                            } else if (unit.contains('box')) {
                              totalAmountStr = amountStr;
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  totalAmountStr,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)} (${item.unitPriceDisplay})',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Quantity Controls on a new row
                      Row(
                        children: [
                          _buildQuantityButton(
                            icon: Icons.remove,
                            onPressed: () {
                              if (item.quantity > 1) {
                                cart.updateQuantity(item.productId, item.quantity - 1);
                              } else {
                                cart.removeFromCart(item.productId);
                              }
                            },
                          ),
                          Container(
                            width: 40,
                            height: 32,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          _buildQuantityButton(
                            icon: Icons.add,
                            onPressed: () {
                              cart.updateQuantity(item.productId, item.quantity + 1);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.white),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartService cart) {
    final total = cart.getTotal();
    int deliveryFee = 0;
    String feeLabel = '';
    if (total < 500) {
      deliveryFee = 40;
      feeLabel = '₹40';
    } else if (total < 1000) {
      deliveryFee = 20;
      feeLabel = '₹20';
    } else {
      deliveryFee = 0;
      feeLabel = 'Free';
    }
    final totalWithFee = total + deliveryFee;

    // Progress bar logic
    double progress = 0;
    String progressMessage = '';
    Color barColor = Colors.green;
    if (total < 500) {
      progress = (total / 500).clamp(0.0, 1.0);
      progressMessage = 'Add ₹${(500 - total).ceil()} more to reduce delivery fee to ₹20';
      barColor = Colors.green;
    } else if (total < 1000) {
      progress = ((total - 500) / 500).clamp(0.0, 1.0);
      progressMessage = 'Add ₹${(1000 - total).ceil()} more to get free delivery';
      barColor = Colors.orange;
    } else {
      progress = 1.0;
      progressMessage = 'You have unlocked free delivery!';
      barColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delivery Fee Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 18,
                      width: MediaQuery.of(context).size.width * progress,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          progressMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
            // Price Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Fee:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  feeLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: deliveryFee == 0 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${cart.items.length} items):',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '₹${totalWithFee.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCheckingOut ? null : () => _proceedToCheckout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isCheckingOut
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_checkout),
                          const SizedBox(width: 8),
                          Text(
                            'Proceed to Checkout',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

  void _proceedToCheckout(BuildContext context) async {
    setState(() {
      _isCheckingOut = true;
    });

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isCheckingOut = false;
    });

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CheckoutScreen(),
        ),
      );
    }
  }

  double _parsePrice(String price) {
    final match = RegExp(r'([0-9]+(\.[0-9]+)?)').firstMatch(price);
    return match != null ? double.parse(match.group(0)!) : 0.0;
  }
} 