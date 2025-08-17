import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemoryService extends ChangeNotifier {
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal();

  Timer? _memoryCheckTimer;
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final Map<String, DateTime> _resourceTimestamps = {};
  
  bool _isMonitoring = false;
  int _lastMemoryUsage = 0;
  final List<int> _memoryHistory = [];

  bool get isMonitoring => _isMonitoring;
  int get lastMemoryUsage => _lastMemoryUsage;
  List<int> get memoryHistory => List.unmodifiable(_memoryHistory);

  // Start memory monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    notifyListeners();

    // Start periodic memory checks
    _memoryCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkMemoryUsage(),
    );

    // Start leak tracking in debug mode
    if (kDebugMode) {
      await _startLeakTracking();
    }

    developer.log('Memory monitoring started', name: 'MemoryService');
  }

  // Stop memory monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
    notifyListeners();

    developer.log('Memory monitoring stopped', name: 'MemoryService');
  }

  // Check current memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      _lastMemoryUsage = memoryInfo['used'] ?? 0;
      
      _memoryHistory.add(_lastMemoryUsage);
      
      // Keep only last 100 entries
      if (_memoryHistory.length > 100) {
        _memoryHistory.removeAt(0);
      }

      // Check for memory leaks
      if (_lastMemoryUsage > 100 * 1024 * 1024) { // 100MB threshold
        _handleHighMemoryUsage();
      }

      notifyListeners();
    } catch (e) {
      developer.log('Error checking memory usage: $e', name: 'MemoryService');
    }
  }

  // Get memory information
  Future<Map<String, int>> _getMemoryInfo() async {
    try {
      const platform = MethodChannel('memory_service');
      final result = await platform.invokeMethod('getMemoryInfo');
      return Map<String, int>.from(result);
    } catch (e) {
      // Fallback to basic memory info
      return {
        'total': 0,
        'used': 0,
        'free': 0,
      };
    }
  }

  // Handle high memory usage
  void _handleHighMemoryUsage() {
    developer.log('High memory usage detected: ${_lastMemoryUsage}MB', name: 'MemoryService');
    
    // Clear old resources
    _clearOldResources();
    
    // Force garbage collection if available
    _forceGarbageCollection();
  }

  // Clear old resources
  void _clearOldResources() {
    final now = DateTime.now();
    final resourcesToRemove = <String>[];

    for (final entry in _resourceTimestamps.entries) {
      if (now.difference(entry.value).inMinutes > 30) {
        resourcesToRemove.add(entry.key);
      }
    }

    for (final resource in resourcesToRemove) {
      _resourceTimestamps.remove(resource);
    }

    developer.log('Cleared ${resourcesToRemove.length} old resources', name: 'MemoryService');
  }

  // Force garbage collection
  void _forceGarbageCollection() {
    // This is a placeholder for actual GC call
    // In a real implementation, you might use platform channels
    developer.log('Garbage collection requested', name: 'MemoryService');
  }

  // Track resource usage
  void trackResource(String resourceId) {
    _resourceTimestamps[resourceId] = DateTime.now();
  }

  // Release resource
  void releaseResource(String resourceId) {
    _resourceTimestamps.remove(resourceId);
  }

  // Register subscription for cleanup
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  // Register timer for cleanup
  void registerTimer(Timer timer) {
    _timers.add(timer);
  }

  // Cleanup all resources
  void cleanup() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    // Clear resource timestamps
    _resourceTimestamps.clear();

    // Clear memory history
    _memoryHistory.clear();

    developer.log('Memory service cleanup completed', name: 'MemoryService');
  }

  // Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    if (_memoryHistory.isEmpty) {
      return {
        'current': 0,
        'average': 0,
        'peak': 0,
        'trend': 'stable',
      };
    }

    final current = _lastMemoryUsage;
    final average = _memoryHistory.reduce((a, b) => a + b) / _memoryHistory.length;
    final peak = _memoryHistory.reduce((a, b) => a > b ? a : b);

    String trend = 'stable';
    if (_memoryHistory.length >= 2) {
      final recent = _memoryHistory.take(5).reduce((a, b) => a + b) / 5;
      final older = _memoryHistory.skip(_memoryHistory.length - 5).reduce((a, b) => a + b) / 5;
      
      if (recent > older * 1.1) {
        trend = 'increasing';
      } else if (recent < older * 0.9) {
        trend = 'decreasing';
      }
    }

    return {
      'current': current,
      'average': average.round(),
      'peak': peak,
      'trend': trend,
      'tracked_resources': _resourceTimestamps.length,
      'active_subscriptions': _subscriptions.length,
      'active_timers': _timers.length,
    };
  }

  // Start leak tracking (debug mode only)
  Future<void> _startLeakTracking() async {
    if (!kDebugMode) return;

    try {
      // Leak tracking implementation would go here
      // For now, just log that it's enabled
      developer.log('Leak tracking enabled', name: 'MemoryService');
    } catch (e) {
      developer.log('Failed to start leak tracking: $e', name: 'MemoryService');
    }
  }

  // Stop leak tracking
  Future<void> _stopLeakTracking() async {
    if (!kDebugMode) return;

    try {
      // Leak tracking stop implementation would go here
      developer.log('Leak tracking disabled', name: 'MemoryService');
    } catch (e) {
      developer.log('Failed to stop leak tracking: $e', name: 'MemoryService');
    }
  }

  // Optimize memory for large datasets
  void optimizeForLargeDataset() {
    // Clear memory history to free up space
    if (_memoryHistory.length > 50) {
      _memoryHistory.removeRange(0, _memoryHistory.length - 50);
    }

    // Clear old resources more aggressively
    final now = DateTime.now();
    final resourcesToRemove = <String>[];

    for (final entry in _resourceTimestamps.entries) {
      if (now.difference(entry.value).inMinutes > 10) {
        resourcesToRemove.add(entry.key);
      }
    }

    for (final resource in resourcesToRemove) {
      _resourceTimestamps.remove(resource);
    }

    developer.log('Memory optimized for large dataset', name: 'MemoryService');
  }

  // Get memory usage trend
  String getMemoryTrend() {
    if (_memoryHistory.length < 3) return 'insufficient_data';

    final recent = _memoryHistory.take(3).reduce((a, b) => a + b) / 3;
    final older = _memoryHistory.skip(_memoryHistory.length - 3).reduce((a, b) => a + b) / 3;

    if (recent > older * 1.05) {
      return 'increasing';
    } else if (recent < older * 0.95) {
      return 'decreasing';
    } else {
      return 'stable';
    }
  }

  // Check if memory usage is healthy
  bool isMemoryHealthy() {
    return _lastMemoryUsage < 80 * 1024 * 1024; // 80MB threshold
  }

  // Get memory usage percentage
  double getMemoryUsagePercentage() {
    // This is a rough estimation
    const maxMemory = 512 * 1024 * 1024; // 512MB assumed max
    return (_lastMemoryUsage / maxMemory * 100).clamp(0.0, 100.0);
  }

  @override
  void dispose() {
    stopMonitoring();
    cleanup();
    super.dispose();
  }
}

// Memory-aware widget mixin
mixin MemoryAwareWidget<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<String> _resourceIds = [];

  @override
  void initState() {
    super.initState();
    _registerWithMemoryService();
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _registerWithMemoryService() {
    final memoryService = MemoryService();
    // Create a dummy subscription for tracking
    final dummySubscription = Stream.empty().listen((_) {});
    memoryService.registerSubscription(dummySubscription);
  }

  void _cleanupResources() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    // Release all tracked resources
    for (final resourceId in _resourceIds) {
      MemoryService().releaseResource(resourceId);
    }
    _resourceIds.clear();
  }

  // Register a subscription for automatic cleanup
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  // Register a timer for automatic cleanup
  void registerTimer(Timer timer) {
    _timers.add(timer);
  }

  // Track a resource for cleanup
  void trackResource(String resourceId) {
    _resourceIds.add(resourceId);
    MemoryService().trackResource(resourceId);
  }

  // Release a tracked resource
  void releaseResource(String resourceId) {
    _resourceIds.remove(resourceId);
    MemoryService().releaseResource(resourceId);
  }
} 