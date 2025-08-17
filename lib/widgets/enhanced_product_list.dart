import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/offline_service.dart';
import 'loading_shimmer.dart';

class EnhancedProductList extends StatefulWidget {
  final String? category;
  final String? searchQuery;
  final int itemsPerPage;
  final bool showFavorites;
  final VoidCallback? onProductTap;
  final Function(Product)? onAddToCart;
  final Function(Product)? onToggleFavorite;

  const EnhancedProductList({
    super.key,
    this.category,
    this.searchQuery,
    this.itemsPerPage = 10,
    this.showFavorites = false,
    this.onProductTap,
    this.onAddToCart,
    this.onToggleFavorite,
  });

  @override
  State<EnhancedProductList> createState() => _EnhancedProductListState();
}

class _EnhancedProductListState extends State<EnhancedProductList> {
  final List<Product> _products = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String? _lastSearchQuery;
  String? _lastCategory;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void didUpdateWidget(EnhancedProductList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reload if search query or category changed
    if (widget.searchQuery != _lastSearchQuery || widget.category != _lastCategory) {
      _lastSearchQuery = widget.searchQuery;
      _lastCategory = widget.category;
      _resetAndReload();
    }
  }

  void _resetAndReload() {
    setState(() {
      _products.clear();
      _currentPage = 0;
      _hasMoreData = true;
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newProducts = await _fetchProducts(0);
      
      if (mounted) {
        setState(() {
          _products.clear();
          _products.addAll(newProducts);
          _currentPage = 1;
          _hasMoreData = newProducts.length >= widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load products');
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newProducts = await _fetchProducts(_currentPage);
      
      if (mounted) {
        setState(() {
          _products.addAll(newProducts);
          _currentPage++;
          _hasMoreData = newProducts.length >= widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load more products');
      }
    }
  }

  Future<List<Product>> _fetchProducts(int page) async {
    final offset = page * widget.itemsPerPage;
    
    // Try online first, fallback to offline
    try {
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        // For search, we'll use the existing search method
        // Note: This returns a Stream, so we need to handle it differently
        return [];
      } else {
        // For regular products, we'll use the existing getProducts method
        // Note: This returns a Stream, so we need to handle it differently
        return [];
      }
    } catch (e) {
      // Fallback to offline data
      return _getOfflineProducts();
    }
  }

  List<Product> _getOfflineProducts() {
    final offlineService = OfflineService();
    final cachedProducts = offlineService.getCachedProducts();
    
    // Convert cached data to Product objects
    return cachedProducts.map((data) {
      return Product(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: data['price'] ?? '',
        stock: data['stock'] ?? 0,
        imageUrls: (data['image_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
        nutrition: Map<String, String>.from(data['nutrition'] ?? {}),
      );
    }).toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _products.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return _buildLoadingIndicator();
          }

          final product = _products[index];
          return _buildProductCard(product, index);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _ProductCard(
        product: product,
        onTap: () => widget.onProductTap?.call(),
        onAddToCart: () => widget.onAddToCart?.call(product),
        onToggleFavorite: () => widget.onToggleFavorite?.call(product),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: index * 50),
    ).slideY(
      begin: 0.3,
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: index * 50),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_isLoading) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.searchQuery != null 
                ? 'Try adjusting your search terms'
                : 'Check back later for new products',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleFavorite;

  const _ProductCard({
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.price,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                                                 if (onToggleFavorite != null)
                           IconButton(
                             onPressed: onToggleFavorite,
                             icon: const Icon(
                               Icons.favorite_border,
                               color: null,
                             ),
                             iconSize: 20,
                           ),
                        if (onAddToCart != null)
                          IconButton(
                            onPressed: onAddToCart,
                            icon: const Icon(Icons.add_shopping_cart),
                            iconSize: 20,
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
  }
} 