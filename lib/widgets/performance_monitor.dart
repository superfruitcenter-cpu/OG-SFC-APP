import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/memory_service.dart';
import '../services/offline_service.dart';
import '../utils/memory_utils.dart';
import '../utils/offline_utils.dart';

class PerformanceMonitor extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onOptimize;

  const PerformanceMonitor({
    super.key,
    this.showDetails = false,
    this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<MemoryService, OfflineService>(
      builder: (context, memoryService, offlineService, child) {
        final memoryStats = memoryService.getMemoryStats();
        final memoryPercentage = MemoryUtils.getMemoryUsagePercentage(context);
        final memoryTrend = MemoryUtils.getMemoryTrend(context);
        final isMemoryHealthy = MemoryUtils.isMemoryHealthy(context);
        final needsOptimization = MemoryUtils.needsMemoryOptimization(context);

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Performance Monitor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (needsOptimization)
                      IconButton(
                        onPressed: onOptimize ?? () => _optimizePerformance(context),
                        icon: const Icon(Icons.tune),
                        tooltip: 'Optimize Performance',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Memory Usage Section
                _buildMemorySection(
                  context,
                  memoryPercentage,
                  memoryTrend,
                  isMemoryHealthy,
                  memoryStats,
                ),
                
                const SizedBox(height: 16),
                
                // Network Status Section
                _buildNetworkSection(context, offlineService),
                
                if (showDetails) ...[
                  const SizedBox(height: 16),
                  _buildDetailedStats(context, memoryStats),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemorySection(
    BuildContext context,
    double memoryPercentage,
    String memoryTrend,
    bool isMemoryHealthy,
    Map<String, dynamic> memoryStats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Memory Usage',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: memoryPercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  MemoryUtils.getMemoryStatusColor(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${memoryPercentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              MemoryUtils.getMemoryStatusIcon(context),
              size: 16,
              color: MemoryUtils.getMemoryStatusColor(context),
            ),
            const SizedBox(width: 4),
            Text(
              MemoryUtils.getMemoryStatusText(context),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MemoryUtils.getMemoryStatusColor(context),
              ),
            ),
            const Spacer(),
            Text(
              'Trend: $memoryTrend',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkSection(BuildContext context, OfflineService offlineService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network Status',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              offlineService.isOnline ? Icons.wifi : Icons.wifi_off,
              size: 16,
              color: offlineService.isOnline ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              offlineService.isOnline ? 'Online' : 'Offline',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: offlineService.isOnline ? Colors.green : Colors.orange,
              ),
            ),
            const Spacer(),
            if (!offlineService.isOnline)
              Text(
                'Cached data available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStats(BuildContext context, Map<String, dynamic> memoryStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Statistics',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatRow('Current Memory', MemoryUtils.formatMemorySize(memoryStats['current'] ?? 0)),
        _buildStatRow('Average Memory', MemoryUtils.formatMemorySize(memoryStats['average'] ?? 0)),
        _buildStatRow('Peak Memory', MemoryUtils.formatMemorySize(memoryStats['peak'] ?? 0)),
        _buildStatRow('Tracked Resources', '${memoryStats['tracked_resources'] ?? 0}'),
        _buildStatRow('Active Subscriptions', '${memoryStats['active_subscriptions'] ?? 0}'),
        _buildStatRow('Active Timers', '${memoryStats['active_timers'] ?? 0}'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _optimizePerformance(BuildContext context) {
    MemoryUtils.showMemoryWarningDialog(context);
  }
}

// Performance indicator widget
class PerformanceIndicator extends StatelessWidget {
  final bool showText;
  final VoidCallback? onTap;

  const PerformanceIndicator({
    super.key,
    this.showText = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryService>(
      builder: (context, memoryService, child) {
        final memoryPercentage = MemoryUtils.getMemoryUsagePercentage(context);
        final isHealthy = MemoryUtils.isMemoryHealthy(context);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.memory,
                  size: 12,
                  color: Colors.white,
                ),
                if (showText) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${memoryPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Performance overlay
class PerformanceOverlay extends StatelessWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MemoryService>(
      builder: (context, memoryService, child) {
        if (!showOverlay) {
          return this.child;
        }

        final needsOptimization = MemoryUtils.needsMemoryOptimization(context);

        if (!needsOptimization) {
          return this.child;
        }

        return Stack(
          children: [
            this.child,
            Positioned(
              top: 50,
              right: 16,
              child: PerformanceIndicator(
                showText: true,
                onTap: () => MemoryUtils.showMemoryWarningDialog(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Performance-aware scaffold
class PerformanceAwareScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool showPerformanceIndicator;

  const PerformanceAwareScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.showPerformanceIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: PerformanceOverlay(
        showOverlay: showPerformanceIndicator,
        child: body ?? const SizedBox.shrink(),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }
} 