import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/responsive_utils.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Amount and quantity state
  String _selectedAmount = '';
  String _selectedUnit = '';

  List<String> _amountOptions = [];
  bool _amountOptionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
    _fetchAmountOptions();
    // Set default amount/unit based on price (will be overridden if amountOptions are loaded)
    final price = widget.product.price.toLowerCase();
    if (price.endsWith('/kg')) {
      _selectedAmount = '1kg';
      _selectedUnit = 'kg';
    } else if (price.endsWith('/piece')) {
      _selectedAmount = '1pc';
      _selectedUnit = 'piece';
    } else if (price.endsWith('/box')) {
      _selectedAmount = '1 box';
      _selectedUnit = 'box';
    } else {
      _selectedAmount = '';
      _selectedUnit = '';
    }
  }

  Future<void> _fetchAmountOptions() async {
    final doc = await FirebaseFirestore.instance.collection('products').doc(widget.product.id).get();
    if (doc.exists && doc.data() != null && doc.data()!['amountOptions'] != null) {
      setState(() {
        _amountOptions = List<String>.from(doc.data()!['amountOptions']);
        _amountOptionsLoaded = true;
        if (_amountOptions.isNotEmpty) {
          _selectedAmount = _amountOptions[0];
          // Try to guess unit from the first chip
          final lower = _selectedAmount.toLowerCase();
          if (lower.contains('kg') || lower.contains('g')) {
            _selectedUnit = 'kg';
          } else if (lower.contains('piece') || lower.contains('pc')) {
            _selectedUnit = 'piece';
          } else if (lower.contains('box')) {
            _selectedUnit = 'box';
          } else {
            _selectedUnit = '';
          }
        }
      });
    } else {
      setState(() {
        _amountOptions = [];
        _amountOptionsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveUtils.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductInfo(),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                  _buildNutritionInfo(),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                  _buildAmountSelector(),
                  SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
                  _buildAddToCartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: ResponsiveUtils.responsiveHeight(context, baseHeight: 320),
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageCarousel(),
      ),
      actions: [
        // Share button removed
      ],
    );
  }

  Widget _buildImageCarousel() {
    if (widget.product.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.image, 
            size: ResponsiveUtils.responsiveIconSize(context, baseSize: 64), 
            color: Colors.grey
          ),
        ),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.product.imageUrls.length,
          itemBuilder: (context, index) {
            return Hero(
              tag: 'product-image-${widget.product.id}',
              child: CachedNetworkImage(
                imageUrl: widget.product.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image, 
                    size: ResponsiveUtils.responsiveIconSize(context, baseSize: 48), 
                    color: Colors.grey
                  ),
                ),
              ),
            );
          },
        ),
        // Overlay expand button
        Positioned(
          top: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
          right: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
          child: Material(
            color: Colors.black45,
            shape: const CircleBorder(),
            child: IconButton(
              icon: Icon(
                Icons.open_in_full, 
                color: Colors.white,
                size: ResponsiveUtils.responsiveIconSize(context),
              ),
              onPressed: () {
                _showFullScreenImages(context);
              },
              tooltip: 'View full image',
            ),
          ),
        ),
        if (widget.product.imageUrls.length > 1)
          Positioned(
            bottom: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.product.imageUrls.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
                  width: _currentPage == index 
                      ? ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)
                      : ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                  height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 4)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullScreenImages(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink(); // Required by API, actual child in transitionBuilder
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: 0.95 + 0.05 * anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.white,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: widget.product.imageUrls.length,
                    controller: PageController(initialPage: _currentPage),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        child: Center(
                          child: Hero(
                            tag: 'product-image-${widget.product.id}',
                            child: CachedNetworkImage(
                              imageUrl: widget.product.imageUrls[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 48, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 24,
                    right: 24,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.black, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16))
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 24),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12),
                    vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 6),
                  ),
                  decoration: BoxDecoration(
                    color: widget.product.stock > 0 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
                  ),
                  child: Text(
                    widget.product.stock > 0 ? 'In Stock' : 'Out of Stock',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.product.stock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
            Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    Text(
                      widget.product.price,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                    Text(
                      '${widget.product.stock} units',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16))
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Nutrition Information (per 100 gram)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
            _buildNutritionRow('Calories', '52 kcal'),
            _buildNutritionRow('Protein', '0.3g'),
            _buildNutritionRow('Carbohydrates', '14g'),
            _buildNutritionRow('Fiber', '2.4g'),
            _buildNutritionRow('Vitamin C', '4.6mg'),
            _buildNutritionRow('Potassium', '107mg'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSelector() {
    if (!_amountOptionsLoaded) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
          ),
        ),
      );
    }
    if (_amountOptions.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Amount', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
          )
        ),
        SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
        Wrap(
          spacing: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12),
          children: _amountOptions.map((opt) => ChoiceChip(
            label: Text(
              opt,
              style: TextStyle(
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
              ),
            ),
            selected: _selectedAmount == opt,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedAmount = opt;
                  final lower = opt.toLowerCase();
                  if (lower.contains('kg') || lower.contains('g')) {
                    _selectedUnit = 'kg';
                  } else if (lower.contains('piece') || lower.contains('pc')) {
                    _selectedUnit = 'piece';
                  } else if (lower.contains('box')) {
                    _selectedUnit = 'box';
                  } else {
                    _selectedUnit = '';
                  }
                });
              }
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveUtils.responsiveHeight(context, baseHeight: 56),
      child: ElevatedButton(
        onPressed: widget.product.stock > 0 && _selectedAmount.isNotEmpty ? _handleAddToCart : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16))
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.product.stock > 0 ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
              size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
            ),
            SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
            Text(
              widget.product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddToCart() async {
    final cart = Provider.of<CartService>(context, listen: false);
    // Parse amount (e.g., '2kg', '500g', '1pc', '2pcs', '1 box')
    double singleAmount = 1;
    String unit = _selectedUnit;
    final amountStr = _selectedAmount.toLowerCase();
    if (unit == 'kg') {
      if (amountStr.endsWith('kg')) {
        singleAmount = double.tryParse(amountStr.replaceAll('kg', '').trim()) ?? 1;
      } else if (amountStr.endsWith('g')) {
        singleAmount = (double.tryParse(amountStr.replaceAll('g', '').trim()) ?? 100) / 1000.0;
      }
    } else if (unit == 'piece') {
      final pcs = RegExp(r'(\d+)').firstMatch(amountStr);
      singleAmount = pcs != null ? double.tryParse(pcs.group(1)!) ?? 1 : 1;
    } else if (unit == 'box') {
      final boxes = RegExp(r'(\d+)').firstMatch(amountStr);
      singleAmount = boxes != null ? double.tryParse(boxes.group(1)!) ?? 1 : 1;
    }
    final totalAmount = singleAmount; // Always 1 quantity
    // Parse price per unit
    double unitPrice = 0;
    final priceStr = widget.product.price.toLowerCase();
    final priceMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(priceStr);
    if (priceMatch != null) {
      unitPrice = double.tryParse(priceMatch.group(1)!) ?? 0;
    }
    final totalPrice = unitPrice * totalAmount;
    final unitPriceDisplay = widget.product.price;
    final cartItem = CartItem(
      productId: widget.product.id,
      name: widget.product.name,
      price: widget.product.price,
      quantity: 1, // Always 1
      imageUrls: widget.product.imageUrls,
      amount: _selectedAmount,
      unit: _selectedUnit,
      unitPrice: unitPrice,
      unitPriceDisplay: unitPriceDisplay,
      totalPrice: totalPrice,
    );
    cart.addToCart(cartItem);
    if (mounted) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildSuccessBottomSheet(),
      );
    }
  }

  Widget _buildSuccessBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24))
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4),
              height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 2)),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: ResponsiveUtils.responsiveIconSize(context, baseSize: 48),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
            Text(
              'Added to cart!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
            Text(
              widget.product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
              ),
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12))
                      ),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacementNamed('/dashboard', arguments: 2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12))
                      ),
                    ),
                    child: Text(
                      'View Cart',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
          ],
        ),
      ),
    );
  }
} 