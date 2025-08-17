import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import '../providers/notification_provider.dart';
import 'categories_screen.dart';
import 'notifications_screen.dart';
import 'product_details_screen.dart';
import '../models/product.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductListScreen extends StatefulWidget {
  final String? initialCategory;
  
  const ProductListScreen({super.key, this.initialCategory});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Fresh';

  @override
  void initState() {
    super.initState();
    // Set initial category if provided
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Fruits'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          // Notification Bell Button
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.fiber_new),
                        title: const Text('Fresh (Newest)'),
                        selected: _selectedFilter == 'Fresh',
                        onTap: () => Navigator.pop(context, 'Fresh'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.sort_by_alpha),
                        title: const Text('Name (A-Z)'),
                        selected: _selectedFilter == 'Name',
                        onTap: () => Navigator.pop(context, 'Name'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.attach_money),
                        title: const Text('Price (Low to High)'),
                        selected: _selectedFilter == 'Price',
                        onTap: () => Navigator.pop(context, 'Price'),
                      ),
                    ],
                  ),
                ),
              );
              if (result != null && result != _selectedFilter) {
                setState(() {
                  _selectedFilter = result;
                });
              }
            },
          ),
          // Remove old category icon, replaced below
          // Clear Category Button (if category is selected)
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search fruits...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Modern Category Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const CategoriesScreen(),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedCategory = result;
                      });
                    }
                  },
                  icon: const Icon(Icons.category, color: Colors.white),
                  label: const Text('Category', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
                  .orderBy(_selectedFilter == 'Name' ? 'name' : _selectedFilter == 'Price' ? 'price' : 'created_at', descending: _selectedFilter == 'Fresh')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      );
                    },
                  );
          }

          if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          // Filter products by category if selected
                var filteredDocs = _selectedCategory != null
              ? docs.where((doc) {
                  final product = doc.data() as Map<String, dynamic>;
                  return product['category'] == _selectedCategory;
                }).toList()
              : docs;

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filteredDocs = filteredDocs.where((doc) {
                    final product = doc.data() as Map<String, dynamic>;
                    final name = (product['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();
                }

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                        Image.asset('assets/images/empty_box.png', height: 120),
                        const SizedBox(height: 16),
                        const Text('No products match your search.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                              _searchController.clear();
                              _searchQuery = '';
                      });
                    },
                    child: const Text('Show All Products'),
                  ),
                ],
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: GridView.builder(
              key: ValueKey(filteredDocs.length),
              padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
            ),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final product = doc.data() as Map<String, dynamic>;
              final isOutOfStock = product['is_out_of_stock'] ?? false;
              String unit = (product['unit'] ?? 'unit').toString();
              unit = unit.replaceAll(RegExp(r'unit', caseSensitive: false), '').trim();
              if (unit.isEmpty) unit = 'unit';
                String priceDisplay = '${product['price'] ?? '0'}';
                final imageUrls = (product['image_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 60)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                onTap: () {
                  final productObj = Product(
                    id: doc.id,
                    name: product['name'] ?? '',
                    description: product['description'] ?? '',
                              price: product['price'] ?? '0',
                    stock: product['stock'] ?? 0,
                    imageUrls: imageUrls,
                    createdAt: (product['created_at'] as Timestamp).toDate(),
                    updatedAt: (product['updated_at'] as Timestamp?)?.toDate() ?? (product['created_at'] as Timestamp).toDate(),
                    nutrition: product['nutrition'] != null ? Map<String, String>.from(product['nutrition']) : {},
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(
                        product: productObj,
                      ),
                    ),
                  );
                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                                  flex: 3,
                            child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                    child: Hero(
                                      tag: 'product-image-${doc.id}',
                                      child: product['image_urls'] != null && product['image_urls'].isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: product['image_urls'][0],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (context, url) => Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor: Colors.grey[100]!,
                                                child: Container(
                                                  color: Colors.grey[200],
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image, size: 48, color: Colors.grey),
                                              ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
                                    ),
                        ),
                      ),
                                ),
                      Padding(
                            padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? '',
                              style: const TextStyle(
                                    fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                            Text(
                                            product['price'] ?? '0',
                              style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                ),
                              ),
                                if (isOutOfStock)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      color: Colors.red,
                                                  fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                ),
                                              ),
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
              );
            },
            ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerImage extends StatelessWidget {
  final String url;
  const _ShimmerImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            color: Colors.grey[300],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
      ),
    );
  }
} 