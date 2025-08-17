import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'order_details_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fruit_store_user_app/screens/enhanced_dashboard.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fruit_store_user_app/utils/responsive_utils.dart';

// Add Firestore error logging helper
Future<void> _logOrdersError(String context, dynamic error) async {
  try {
    await FirebaseFirestore.instance.collection('orders_errors').add({
      'context': context,
      'error': error.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (_) {}
}

// Add a function to map backend status to user-friendly status and color
String getUserOrderStatus(String backendStatus) {
  switch (backendStatus.toLowerCase()) {
    case 'ordered':
      return 'Ordered';
    case 'packed':
      return 'Packed';
    case 'out for delivery':
      return 'Out for Delivery';
    case 'delivered':
      return 'Delivered';
    default:
      return 'Ordered';
  }
}
Color getUserOrderStatusColor(String userStatus) {
  switch (userStatus) {
    case 'Ordered':
      return Colors.orange;
    case 'Packed':
      return Colors.blue;
    case 'Out for Delivery':
      return Colors.deepPurple;
    case 'Delivered':
      return Color(0xFF4CAF50);
    default:
      return Colors.orange;
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    // Add search controller and state
    return _OrdersScreenBody(userId: user.uid);
  }
}

class _OrdersScreenBody extends StatefulWidget {
  final String userId;
  const _OrdersScreenBody({required this.userId});

  @override
  State<_OrdersScreenBody> createState() => _OrdersScreenBodyState();
}

class _OrdersScreenBodyState extends State<_OrdersScreenBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPaymentFilter = 'All';

  List<DocumentSnapshot> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _perPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading && _hasMore) {
      _fetchOrders();
    }
  }

  Future<void> _fetchOrders({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      Query query = FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: widget.userId)
          .orderBy('created_at', descending: true)
          .limit(_perPage);
      if (!refresh && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      final snapshot = await query.get();
      if (refresh) {
        _orders = snapshot.docs;
      } else {
        _orders.addAll(snapshot.docs);
      }
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length == _perPage;
    } catch (e) {
      _logOrdersError('order_fetch', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e'), backgroundColor: Colors.red, duration: Duration(milliseconds: 1500)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshOrders() async {
    _lastDocument = null;
    _hasMore = true;
    await _fetchOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool foundHome = false;
        Navigator.of(context).popUntil((route) {
          if (route.settings.name == '/dashboard' || route.settings.name == '/' || route.settings.name == 'home') {
            foundHome = true;
          }
          return true;
        });
        if (!foundHome) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashboardScreen()),
          );
        }
        return false;
      },
      child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
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
              child: Column(
                children: [
                  Padding(
                    padding: ResponsiveUtils.responsivePadding(
                      context,
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                              hintText: 'Search by name, date, or order ID...',
                              prefixIcon: Icon(
                                Icons.search, 
                                color: Color(0xFF4CAF50),
                                size: ResponsiveUtils.responsiveIconSize(context, baseSize: 20),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear, 
                                        color: Colors.redAccent,
                                        size: ResponsiveUtils.responsiveIconSize(context, baseSize: 20),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16),
                                ),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: ResponsiveUtils.responsivePadding(
                                context,
                                horizontal: 20,
                                vertical: 16,
                              ),
                              hintStyle: TextStyle(
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: _selectedPaymentFilter == 'All' ? Colors.grey : Color(0xFF4CAF50),
                            size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                          ),
                          tooltip: 'Filter by payment method',
                          onPressed: () async {
                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                    ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 20),
                                  ),
                                ),
                              ),
                              builder: (context) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: Icon(
                                          Icons.all_inclusive,
                                          size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                                        ),
                                        title: Text(
                                          'All',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                          ),
                                        ),
                                        selected: _selectedPaymentFilter == 'All',
                                        onTap: () => Navigator.pop(context, 'All'),
                                      ),
                                      ListTile(
                                        leading: Icon(
                                          Icons.money,
                                          size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                                        ),
                                        title: Text(
                                          'Cash on Delivery',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                          ),
                                        ),
                                        selected: _selectedPaymentFilter == 'COD',
                                        onTap: () => Navigator.pop(context, 'COD'),
                                      ),
                                      ListTile(
                                        leading: Icon(
                                          Icons.credit_card,
                                          size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                                        ),
                                        title: Text(
                                          'Online Payment',
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                          ),
                                        ),
                                        selected: _selectedPaymentFilter == 'Online',
                                        onTap: () => Navigator.pop(context, 'Online'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                            if (selected != null && selected != _selectedPaymentFilter) {
                              setState(() {
                                _selectedPaymentFilter = selected;
                              });
                            }
                          },
                        ),
                        if (_selectedPaymentFilter != 'All')
                          IconButton(
                            icon: Icon(
                              Icons.clear, 
                              color: Colors.redAccent,
                              size: ResponsiveUtils.responsiveIconSize(context, baseSize: 20),
                            ),
                            tooltip: 'Clear payment filter',
                            onPressed: () {
                              setState(() {
                                _selectedPaymentFilter = 'All';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  Expanded(
            child: RefreshIndicator(
                      onRefresh: _refreshOrders,
                      child: _orders.isEmpty && !_isLoading
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                padding: const EdgeInsets.all(16),
                              itemCount: _orders.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                                if (index >= _orders.length) {
                                  return Center(
                                    child: Padding(
                                      padding: ResponsiveUtils.responsivePadding(context, baseSpacing: 16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final doc = _orders[index];
                                final order = doc.data() as Map<String, dynamic>? ?? {};
                                // Apply search and filter in memory
                                final orderId = doc.id.toLowerCase();
                                final items = (order['items'] as List<dynamic>? ?? []);
                                final productNames = items.map((item) => (item['name'] ?? '').toString().toLowerCase()).join(', ');
                                final orderDate = order['created_at'] != null
                                    ? DateFormat('dd MMM yyyy').format((order['created_at'] as Timestamp).toDate()).toLowerCase()
                                    : '';
                                final paymentId = (order['payment_id'] ?? '').toString().toLowerCase();
                                final isCOD = paymentId.contains('cod') || paymentId.contains('cash');
                                final hasProcessingFee = order['processing_fee'] != null && order['processing_fee'].toString().trim().isNotEmpty && order['processing_fee'].toString() != '0';
                                final isOnline = hasProcessingFee;
                                final filterMatch = _selectedPaymentFilter == 'All' ||
                                  (_selectedPaymentFilter == 'COD' && isCOD) ||
                                  (_selectedPaymentFilter == 'Online' && isOnline);
                                final searchMatch = _searchQuery.isEmpty ||
                                  productNames.contains(_searchQuery) ||
                                  orderDate.contains(_searchQuery) ||
                                  orderId.contains(_searchQuery);
                                if (!filterMatch || !searchMatch) return const SizedBox.shrink();
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
                                  child: _buildOrderCard(context, order, doc.id),
                  );
                },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: ResponsiveUtils.responsivePadding(context, baseSpacing: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
          ),
          padding: ResponsiveUtils.responsivePadding(context, baseSpacing: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  children: [
                  Container(
                    width: ResponsiveUtils.responsiveWidth(context, baseWidth: 60),
                    height: ResponsiveUtils.responsiveHeight(context, baseHeight: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 10),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: ResponsiveUtils.responsiveWidth(context, baseWidth: 80),
                    height: ResponsiveUtils.responsiveHeight(context, baseHeight: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 10),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
              Container(
                width: double.infinity,
                height: ResponsiveUtils.responsiveHeight(context, baseHeight: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
              Container(
                width: ResponsiveUtils.responsiveWidth(context, baseWidth: 120),
                height: ResponsiveUtils.responsiveHeight(context, baseHeight: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: ResponsiveUtils.responsiveIconSize(context, baseSize: 64),
            color: Colors.red[400],
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
          Text(
            error,
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
            ElevatedButton.icon(
              icon: Icon(
                Icons.refresh,
                size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(
                  ResponsiveUtils.responsiveButtonHeight(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveBorderRadius(context),
                  ),
                ),
              ),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: ResponsiveUtils.responsivePadding(context, baseSpacing: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: ResponsiveUtils.responsiveIconSize(context, baseSize: 80),
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 24)),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 24),
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiFruitImage(List<dynamic> items) {
    // Show only the first image, and a '+n' badge if more than one item
    String? firstImageUrl;
    for (var item in items) {
      final imgList = item['imageUrls'] ?? item['image_url'] ?? [];
      if (imgList is List && imgList.isNotEmpty) {
        firstImageUrl = imgList[0];
        break;
      } else if (imgList is String && imgList.isNotEmpty) {
        firstImageUrl = imgList;
        break;
      }
    }
    return SizedBox(
      width: ResponsiveUtils.responsiveWidth(context, baseWidth: 100),
      height: ResponsiveUtils.responsiveHeight(context, baseHeight: 100),
      child: Stack(
        children: [
          Container(
            width: ResponsiveUtils.responsiveWidth(context, baseWidth: 100),
            height: ResponsiveUtils.responsiveHeight(context, baseHeight: 100),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300, 
                width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
              ),
            ),
            child: ClipOval(
              child: firstImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: firstImageUrl,
                      width: ResponsiveUtils.responsiveWidth(context, baseWidth: 100),
                      height: ResponsiveUtils.responsiveHeight(context, baseHeight: 100),
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
                          color: Colors.grey,
                          size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                        ),
                      ),
                    )
                  : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image, 
                      color: Colors.grey,
                      size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                    ),
                  ),
                ),
              ),
          if (items.length > 1)
            Positioned(
              bottom: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
              right: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
              child: Container(
                padding: ResponsiveUtils.responsivePadding(
                  context,
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12),
                  ),
                ),
                child: Text(
                  '+${items.length - 1}',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, String orderId) {
    final items = (order['items'] as List<dynamic>? ?? []);
    final firstItem = items.isNotEmpty ? items[0] : null;
    // Get image for single item, or stacked avatars for multiple
    String? imageUrl;
    if (items.length == 1) {
      final imgList = firstItem?['imageUrls'] ?? firstItem?['image_url'] ?? firstItem?['image_url'] ?? [];
      if (imgList is List && imgList.isNotEmpty) {
        imageUrl = imgList[0];
      } else if (imgList is String && imgList.isNotEmpty) {
        imageUrl = imgList;
      }
    }
    final status = order['payment_status'] ?? 'pending';
    final userStatus = getUserOrderStatus(status);
    final statusColor = getUserOrderStatusColor(userStatus);
    final statusText = userStatus;
    final orderDate = order['created_at'] != null
      ? DateFormat('dd MMM yyyy').format((order['created_at'] as Timestamp).toDate())
      : '';
    // Calculate total including processing fee if present
    double total = 0.0;
    if (order['total_amount'] != null) {
      total = (order['total_amount'] is int)
        ? (order['total_amount'] as int).toDouble()
        : (order['total_amount'] is double)
          ? order['total_amount'] as double
          : double.tryParse(order['total_amount'].toString()) ?? 0.0;
    }
    if (order['processing_fee'] != null && order['processing_fee'].toString().isNotEmpty && order['processing_fee'].toString() != '0') {
      final fee = (order['processing_fee'] is int)
        ? (order['processing_fee'] as int).toDouble()
        : (order['processing_fee'] is double)
          ? order['processing_fee'] as double
          : double.tryParse(order['processing_fee'].toString()) ?? 0.0;
      total += fee;
    }
    final totalAmount = '₹${total.toStringAsFixed(2)}';

    // Prepare names for multiple items
    String itemNames = '';
    if (items.length > 1) {
      itemNames = items.map((item) => item['name'] ?? '').join(', ');
      if (itemNames.length > 22) {
        itemNames = itemNames.substring(0, 20) + '...';
      }
    }

    return _AnimatedOrderCard(
        onTap: () {
          // Ensure order map includes the document ID as 'id'
          final orderWithId = Map<String, dynamic>.from(order);
          orderWithId['id'] = orderId;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(order: orderWithId),
            ),
          );
        },
      child: Card(
        margin: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16),
          ),
        ),
        elevation: 2,
        child: Padding(
          padding: ResponsiveUtils.responsivePadding(context, baseSpacing: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (items.length == 1 && imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 20),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: ResponsiveUtils.responsiveWidth(context, baseWidth: 100),
                    height: ResponsiveUtils.responsiveHeight(context, baseHeight: 100),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: ResponsiveUtils.responsiveWidth(context, baseWidth: 100),
                      height: ResponsiveUtils.responsiveHeight(context, baseHeight: 100),
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: ResponsiveUtils.responsiveWidth(context, baseWidth: 100),
                      height: ResponsiveUtils.responsiveHeight(context, baseHeight: 100),
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image, 
                        color: Colors.grey,
                        size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                      ),
                    ),
                  ),
                )
              else if (items.length > 1)
                _buildMultiFruitImage(items)
              else
                Container(
                  width: ResponsiveUtils.responsiveWidth(context, baseWidth: 100),
                  height: ResponsiveUtils.responsiveHeight(context, baseHeight: 100),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 20),
                    ),
                  ),
                  child: Icon(
                    Icons.image, 
                    color: Colors.grey,
                    size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24),
                  ),
                ),
              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          orderDate,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      items.length == 1
                        ? (firstItem != null ? firstItem['name'] ?? '' : '')
                        : itemNames,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalAmount,
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

class _AnimatedOrderCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedOrderCard({required this.child, required this.onTap, Key? key}) : super(key: key);

  @override
  State<_AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<_AnimatedOrderCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: widget.child,
        ),
      ),
    );
  }
} 