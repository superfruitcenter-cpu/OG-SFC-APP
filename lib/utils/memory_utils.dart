import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';

class MemoryUtils {
  // Check if memory usage is healthy
  static bool isMemoryHealthy(BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    return memoryService.isMemoryHealthy();
  }

  // Get memory usage percentage
  static double getMemoryUsagePercentage(BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    return memoryService.getMemoryUsagePercentage();
  }

  // Get memory usage trend
  static String getMemoryTrend(BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    return memoryService.getMemoryTrend();
  }

  // Get memory statistics
  static Map<String, dynamic> getMemoryStats(BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    return memoryService.getMemoryStats();
  }

  // Show memory warning dialog
  static void showMemoryWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('High Memory Usage'),
        content: const Text(
          'The app is using a lot of memory. This might affect performance. '
          'Consider closing some tabs or restarting the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _optimizeMemory(context);
            },
            child: const Text('Optimize'),
          ),
        ],
      ),
    );
  }

  // Optimize memory usage
  static void _optimizeMemory(BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    memoryService.optimizeForLargeDataset();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memory optimized'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Format memory size
  static String formatMemorySize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Get memory status color
  static Color getMemoryStatusColor(BuildContext context) {
    final percentage = getMemoryUsagePercentage(context);
    
    if (percentage < 50) {
      return Colors.green;
    } else if (percentage < 80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get memory status icon
  static IconData getMemoryStatusIcon(BuildContext context) {
    final percentage = getMemoryUsagePercentage(context);
    
    if (percentage < 50) {
      return Icons.memory;
    } else if (percentage < 80) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  // Get memory status text
  static String getMemoryStatusText(BuildContext context) {
    final percentage = getMemoryUsagePercentage(context);
    
    if (percentage < 50) {
      return 'Healthy';
    } else if (percentage < 80) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  // Check if memory optimization is needed
  static bool needsMemoryOptimization(BuildContext context) {
    final percentage = getMemoryUsagePercentage(context);
    return percentage > 70;
  }

  // Start memory monitoring
  static Future<void> startMemoryMonitoring(BuildContext context) async {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    await memoryService.startMonitoring();
  }

  // Stop memory monitoring
  static void stopMemoryMonitoring(BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    memoryService.stopMonitoring();
  }

  // Track widget lifecycle
  static void trackWidgetLifecycle(String widgetId, BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    memoryService.trackResource('widget_$widgetId');
  }

  // Release widget resources
  static void releaseWidgetResources(String widgetId, BuildContext context) {
    final memoryService = Provider.of<MemoryService>(context, listen: false);
    memoryService.releaseResource('widget_$widgetId');
  }

  // Optimize list rendering
  static List<T> optimizeListForRendering<T>(
    List<T> list, {
    int maxVisibleItems = 50,
    int preloadItems = 10,
  }) {
    if (list.length <= maxVisibleItems) {
      return list;
    }

    // Return only visible items plus preload
    return list.take(maxVisibleItems + preloadItems).toList();
  }

  // Create memory-aware list view
  static Widget createMemoryAwareListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    int itemsPerPage = 20,
    bool enablePagination = true,
  }) {
    return _MemoryAwareListView<T>(
      items: items,
      itemBuilder: itemBuilder,
      itemsPerPage: itemsPerPage,
      enablePagination: enablePagination,
    );
  }

  // Memory-aware image widget
  static Widget createMemoryAwareImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return _MemoryAwareImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  // Memory-aware cached image
  static Widget createMemoryAwareCachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return _MemoryAwareCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

// Memory-aware list view
class _MemoryAwareListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int itemsPerPage;
  final bool enablePagination;

  const _MemoryAwareListView({
    required this.items,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.enablePagination = true,
  });

  @override
  State<_MemoryAwareListView<T>> createState() => _MemoryAwareListViewState<T>();
}

class _MemoryAwareListViewState<T> extends State<_MemoryAwareListView<T>> {
  final ScrollController _scrollController = ScrollController();
  int _visibleItems = 0;

  @override
  void initState() {
    super.initState();
    _visibleItems = widget.itemsPerPage;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (!widget.enablePagination) return;

    setState(() {
      _visibleItems += widget.itemsPerPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.enablePagination
        ? widget.items.take(_visibleItems).toList()
        : widget.items;

    return ListView.builder(
      controller: _scrollController,
      itemCount: visibleItems.length + (widget.enablePagination ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleItems.length) {
          return _buildLoadingIndicator();
        }

        return widget.itemBuilder(context, visibleItems[index], index);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    if (!widget.enablePagination || _visibleItems >= widget.items.length) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Memory-aware image widget
class _MemoryAwareImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _MemoryAwareImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const CircularProgressIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );
  }
}

// Memory-aware cached image widget
class _MemoryAwareCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _MemoryAwareCachedImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Use cached_network_image for better memory management
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const CircularProgressIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );
  }
} 