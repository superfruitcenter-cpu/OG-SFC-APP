import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'profile_screen.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'notifications_screen.dart';
import 'product_details_screen.dart';
import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import '../providers/theme_provider.dart';
import 'fruits_suggestor_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'terms_and_conditions_screen.dart';
import '../utils/responsive_utils.dart';

// NotificationPermissionBanner widget
class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({Key? key}) : super(key: key);

  @override
  State<NotificationPermissionBanner> createState() => _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState extends State<NotificationPermissionBanner> {
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _showBanner = !status.isGranted;
    });
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();
    return Material(
      color: Colors.amber[100],
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.notifications_off, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Notifications are disabled. Enable them to get order updates!',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
            TextButton(
              onPressed: _openSettings,
              child: const Text('Enable Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _didSetInitialTab = false;
  String? _selectedCategory;
  String _selectedFilter = 'Fresh';

  DateTime? _lastBackPressed;

  void setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const EnhancedHomeScreen(),
    const OrdersScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSetInitialTab) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < _screens.length) {
        _selectedIndex = args;
      }
      _didSetInitialTab = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize notification service when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = context.read<NotificationProvider>();
      notificationProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        final now = DateTime.now();
        if (_lastBackPressed == null || now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2)),
          );
          return false;
        }
        return true; // Exit the app
      },
      child: Scaffold(
        key: const ValueKey('dashboard_scaffold'),
        body: _screens[_selectedIndex],
        bottomNavigationBar: AppBottomNavBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  const AppBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFFFD600), // Bright yellow for active tab
        elevation: 0,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: Colors.black);
          }
          return const IconThemeData(color: Colors.black);
        }),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        height: ResponsiveUtils.responsiveHeight(context, baseHeight: 64),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: ResponsiveUtils.responsiveIconSize(context)),
            selectedIcon: Icon(Icons.home, size: ResponsiveUtils.responsiveIconSize(context)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined, size: ResponsiveUtils.responsiveIconSize(context)),
            selectedIcon: Icon(Icons.shopping_bag, size: ResponsiveUtils.responsiveIconSize(context)),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined, size: ResponsiveUtils.responsiveIconSize(context)),
            selectedIcon: Icon(Icons.shopping_cart, size: ResponsiveUtils.responsiveIconSize(context)),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: ResponsiveUtils.responsiveIconSize(context)),
            selectedIcon: Icon(Icons.person, size: ResponsiveUtils.responsiveIconSize(context)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  String? _userName;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Fresh';
  String? _selectedCategory = 'All';
  Set<String> _favouriteIds = {};

  Future<List<String>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    final categories = <String>{};
    for (var doc in snapshot.docs) {
      // Support both 'categories' array and 'category' string for backward compatibility
      final data = doc.data();
      if (data['categories'] != null && data['categories'] is List) {
        for (var cat in data['categories']) {
          if (cat != null && cat.toString().isNotEmpty) {
            categories.add(cat.toString());
          }
        }
      } else if (data['category'] != null && data['category'].toString().isNotEmpty) {
        categories.add(data['category'].toString());
      }
    }
    final sorted = categories.toList()..sort();
    return ['All', ...sorted];
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Only fetch the 'name' field for optimization
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      if (doc.exists) {
        final data = doc.data()!;
        final name = (data['name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          setState(() {
            _userName = name.split(' ').first; // Get first name only
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const NotificationPermissionBanner(),
          Expanded(
            child: RefreshIndicator(
        onRefresh: () async {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedFilter = 'Fresh';
                  _selectedCategory = 'All';
                });
                // Force Firestore to fetch fresh data
                await FirebaseFirestore.instance.collection('products').get(const GetOptions(source: Source.server));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            _buildSearchSection(),
            SliverToBoxAdapter(child: _buildFreshArrivalsSection()),
            _buildProductGrid(),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => Column(
            children: [
              Expanded(
                child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerHeader(),
              _buildDrawerItems(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  color: Colors.green[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.email, color: Colors.green[800]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Contact Us',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Email: superfruitcenter@gmail.com',
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 30),
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.shopping_basket,
              size: ResponsiveUtils.responsiveIconSize(context, baseSize: 32),
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16)),
          Text(
            _userName != null ? 'Hello, $_userName!' : 'Super Fruit Center',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
            ),
          ),
          SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
          Text(
            'Fresh fruits delivered to your door',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            'Fruits Suggestor',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            'AI-powered recommendations',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FruitsSuggestorScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.privacy_tip, color: Colors.blue),
          ),
          title: Text(
            'Terms and Conditions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TermsAndConditionsScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.logout, color: Colors.red),
          ),
          title: Text(
            'Logout',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () async {
            Navigator.pop(context);
            try {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            } catch (e) {
              await _logDashboardError('logout', e);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red, duration: Duration(milliseconds: 1500)),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: ResponsiveUtils.responsiveHeight(context, baseHeight: 120),
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF4CAF50),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF4CAF50).withOpacity(0.8)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: ResponsiveUtils.responsivePadding(
                context,
                horizontal: 16,
                vertical: 20,
                horizontalTablet: 24,
                verticalTablet: 24,
                horizontalLarge: 32,
                verticalLarge: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: Icon(
                            Icons.menu, 
                            color: Colors.white,
                            size: ResponsiveUtils.responsiveIconSize(context),
                          ),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back${_userName != null ? ', $_userName' : ''}! 👋',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2)),
                            Text(
                              'Fresh fruits delivered to your door',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 12),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, child) {
                          return Stack(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.notifications, 
                                  color: Colors.white,
                                  size: ResponsiveUtils.responsiveIconSize(context),
                                ),
                                tooltip: 'View notifications',
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
                                  right: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                                  top: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                                  child: Container(
                                    padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2)),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 10)),
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                                      minHeight: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                                    ),
                                    child: Text(
                                      '${notificationProvider.unreadCount}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 10),
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: ResponsiveUtils.responsiveMargin(context),
        padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 15),
              offset: Offset(0, ResponsiveUtils.responsiveSpacing(context, baseSpacing: 5)),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for fresh fruits...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                      ),
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                        size: ResponsiveUtils.responsiveIconSize(context, baseSize: 20),
                      ),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.clear,
                                color: Colors.grey[600],
                                size: ResponsiveUtils.responsiveIconSize(context, baseSize: 16),
                              ),
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
                      borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20),
                      vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                    offset: Offset(0, ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4)),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.tune, 
                  color: Colors.white, 
                  size: ResponsiveUtils.responsiveIconSize(context, baseSize: 24)
                ),
                tooltip: 'Filter',
                onPressed: () async {
                  final selected = await showModalBottomSheet<String>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 24))
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                                width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 40),
                                height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2)),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                                child: Text(
                                  'Sort by',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                                  ),
                                  child: Icon(
                                    Icons.fiber_new, 
                                    color: Colors.green,
                                    size: ResponsiveUtils.responsiveIconSize(context),
                                  ),
                                ),
                                title: Text(
                                  'Fresh (Newest)',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                  ),
                                ),
                                selected: _selectedFilter == 'Fresh',
                                onTap: () => Navigator.pop(context, 'Fresh'),
                              ),
                              ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                                  ),
                                  child: Icon(
                                    Icons.sort_by_alpha, 
                                    color: Colors.blue,
                                    size: ResponsiveUtils.responsiveIconSize(context),
                                  ),
                                ),
                                title: Text(
                                  'Name (A-Z)',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                  ),
                                ),
                                selected: _selectedFilter == 'Name',
                                onTap: () => Navigator.pop(context, 'Name'),
                              ),
                              ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                                  ),
                                  child: Icon(
                                    Icons.attach_money, 
                                    color: Colors.orange,
                                    size: ResponsiveUtils.responsiveIconSize(context),
                                  ),
                                ),
                                title: Text(
                                  'Price (Low to High)',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                                  ),
                                ),
                                selected: _selectedFilter == 'Price',
                                onTap: () => Navigator.pop(context, 'Price'),
                              ),
                              SizedBox(height: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 20)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  if (selected != null && selected != _selectedFilter) {
                    setState(() {
                      _selectedFilter = selected;
                    });
                  }
                },
              ),
            ),
            if (_selectedFilter != 'Fresh' || _searchQuery.isNotEmpty || (_selectedCategory != null && _selectedCategory != 'All'))
              Container(
                margin: EdgeInsets.only(left: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 12)),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.clear_all, 
                    color: Colors.red, 
                    size: ResponsiveUtils.responsiveIconSize(context, baseSize: 20)
                  ),
                  tooltip: 'Clear filters',
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _selectedFilter = 'Fresh';
                      _selectedCategory = 'All';
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveUtils.responsivePadding(
          context,
          horizontal: 16,
          vertical: 8,
          horizontalTablet: 24,
          verticalTablet: 12,
          horizontalLarge: 32,
          verticalLarge: 16,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(
                  'Available',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                  ),
                ),
                selected: _selectedCategory == 'Available',
                selectedColor: Color(0xFF4CAF50),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: _selectedCategory == 'Available' ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? 'Available' : null;
                  });
                },
              ),
              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
              ChoiceChip(
                label: Text(
                  'Out of Stock',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                  ),
                ),
                selected: _selectedCategory == 'Out of Stock',
                selectedColor: Color(0xFF4CAF50),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: _selectedCategory == 'Out of Stock' ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? 'Out of Stock' : null;
                  });
                },
              ),
              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
              ChoiceChip(
                label: Text(
                  'Imported',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                  ),
                ),
                selected: _selectedCategory == 'Imported',
                selectedColor: Color(0xFF4CAF50),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: _selectedCategory == 'Imported' ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? 'Imported' : null;
                  });
                },
              ),
              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
              ChoiceChip(
                label: Text(
                  'High Fiber',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                  ),
                ),
                selected: _selectedCategory == 'High Fiber',
                selectedColor: Color(0xFF4CAF50),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: _selectedCategory == 'High Fiber' ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? 'High Fiber' : null;
                  });
                },
              ),
              SizedBox(width: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8)),
              ChoiceChip(
                label: Text(
                  'High Vitamins & Minerals',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                  ),
                ),
                selected: _selectedCategory == 'High Vitamins & Minerals',
                selectedColor: Color(0xFF4CAF50),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: _selectedCategory == 'High Vitamins & Minerals' ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? 'High Vitamins & Minerals' : null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreshArrivalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.responsivePadding(
            context,
            horizontal: 16,
            vertical: 16,
            horizontalTablet: 24,
            verticalTablet: 20,
            horizontalLarge: 32,
            verticalLarge: 24,
          ),
          child: Text(
            "Today's Arrivals",
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 18)
            ),
          ),
        ),
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('products')
              .orderBy('updated_at', descending: true)
              .limit(9)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              _logDashboardError('fresh_arrivals_fetch', snapshot.error);
              return Center(child: Text('Error:  ${snapshot.error}'));
            }
            final docs = snapshot.data?.docs ?? [];
            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              return _searchQuery.isEmpty || name.contains(_searchQuery);
            }).toList();
            if (filteredDocs.isEmpty) {
              return Padding(
                padding: ResponsiveUtils.responsivePadding(context),
                child: Text(
                  'No fresh arrivals.',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 16),
                  ),
                ),
              );
            }
            return SizedBox(
              height: ResponsiveUtils.responsiveHeight(context, baseHeight: 210),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredDocs.length,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12),
                ),
                itemBuilder: (context, index) {
                  final product = Product.fromFirestore(filteredDocs[index]);
                  return Container(
                    width: ResponsiveUtils.responsiveCardWidth(context),
                    margin: EdgeInsets.only(right: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                    child: Stack(
                      children: [
                        _buildProductCard(product, index),
                        Positioned(
                          top: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                          left: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                              vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 4),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                            ),
                            child: Text(
                              'Fresh',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Available'),
                    selected: _selectedCategory == 'Available',
                    selectedColor: Color(0xFF4CAF50),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedCategory == 'Available' ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'Available' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Out of Stock'),
                    selected: _selectedCategory == 'Out of Stock',
                    selectedColor: Color(0xFF4CAF50),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedCategory == 'Out of Stock' ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'Out of Stock' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Imported'),
                    selected: _selectedCategory == 'Imported',
                    selectedColor: Color(0xFF4CAF50),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedCategory == 'Imported' ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'Imported' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('High Fiber'),
                    selected: _selectedCategory == 'High Fiber',
                    selectedColor: Color(0xFF4CAF50),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedCategory == 'High Fiber' ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'High Fiber' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('High Vitamins & Minerals'),
                    selected: _selectedCategory == 'High Vitamins & Minerals',
                    selectedColor: Color(0xFF4CAF50),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedCategory == 'High Vitamins & Minerals' ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'High Vitamins & Minerals' : null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'All Fruits',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                _logDashboardError('product_fetch', snapshot.error);
                return Center(child: Text('Error:  ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              final filteredProducts = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
                // Static chip filter logic
                bool matchesCategory = true;
                if (_selectedCategory == 'Available') {
                  matchesCategory = (data['stock'] ?? 0) > 0;
                } else if (_selectedCategory == 'Out of Stock') {
                  matchesCategory = (data['stock'] ?? 0) == 0;
                } else if (_selectedCategory == 'Imported') {
                  matchesCategory = (data['imported'] == true);
                } else if (_selectedCategory == 'High Fiber') {
                  matchesCategory = (data['high_fiber'] == true);
                } else if (_selectedCategory == 'High Vitamins & Minerals') {
                  matchesCategory = (data['high_vitamins_minerals'] == true);
                }
                return matchesSearch && matchesCategory;
              }).toList();

              // Sort based on _selectedFilter
              filteredProducts.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                if (_selectedFilter == 'Name') {
                  return (aData['name'] ?? '').toString().toLowerCase().compareTo((bData['name'] ?? '').toString().toLowerCase());
                } else if (_selectedFilter == 'Price') {
                  // Extract numeric price for comparison, only before '/'
                  double parsePrice(dynamic price) {
                    final str = price is String ? price : price.toString();
                    final beforeSlash = str.contains('/') ? str.split('/')[0] : str;
                    return double.tryParse(beforeSlash.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                  }
                  return parsePrice(aData['price']).compareTo(parsePrice(bData['price']));
                } else if (_selectedFilter == 'Fresh') {
                  final aCreated = (aData['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  final bCreated = (bData['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  return bCreated.compareTo(aCreated); // Newest first
                }
                return 0;
              });

              if (filteredProducts.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text('No fruits found.'),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: ResponsiveUtils.responsivePadding(
                  context,
                  horizontal: 16,
                  horizontalTablet: 24,
                  horizontalLarge: 32,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveUtils.responsiveGridCrossAxisCount(context),
                  childAspectRatio: ResponsiveUtils.responsiveAspectRatio(context),
                  crossAxisSpacing: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                  mainAxisSpacing: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 16),
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = Product.fromFirestore(filteredProducts[index]);
                  return _buildProductCard(product, index);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.white,
                    ),
                    const Spacer(),
                    Container(
                      height: 20,
                      width: 80,
                      color: Colors.white,
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

  Widget _buildProductCard(Product product, int index) {
    final isOutOfStock = product.stock <= 0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
              offset: Offset(0, ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2)),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16))
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[50]!,
                              Colors.grey[100]!,
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 16))
                          ),
                          child: product.imageUrls.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrls[0],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.grey[200]!, Colors.grey[100]!],
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.grey[200]!, Colors.grey[100]!],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.image_outlined, 
                                      size: ResponsiveUtils.responsiveIconSize(context, baseSize: 32), 
                                      color: Colors.grey
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.grey[200]!, Colors.grey[100]!],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.image_outlined, 
                                    size: ResponsiveUtils.responsiveIconSize(context, baseSize: 32), 
                                    color: Colors.grey
                                  ),
                                ),
                        ),
                      ),
                      // Stock status badge
                      if (isOutOfStock)
                        Positioned(
                          top: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                          right: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 6),
                              vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 2),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveUtils.responsiveSpacing(context, baseSpacing: 12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 8),
                            vertical: ResponsiveUtils.responsiveSpacing(context, baseSpacing: 6),
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.responsiveBorderRadius(context, baseRadius: 8)),
                          ),
                          child: Text(
                            product.price,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.responsiveFontSize(context, baseSize: 14),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Add Firestore error logging helper
Future<void> _logDashboardError(String context, dynamic error) async {
  try {
    await FirebaseFirestore.instance.collection('dashboard_errors').add({
      'context': context,
      'error': error.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Fallback to print if Firestore fails
    print('Dashboard Error in $context: $error');
  }
}


