import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace, VoidCallback onRetry)? errorBuilder;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = _handleFlutterError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    if (mounted) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      widget.onError?.call();
    }
  }

  void _handleError(Object error, StackTrace? stackTrace) {
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
      widget.onError?.call();
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _stackTrace, _retry) ??
          _DefaultErrorWidget(
            error: _error!,
            stackTrace: _stackTrace,
            onRetry: _retry,
          );
    }

    return widget.child;
  }

  @override
  void dispose() {
    FlutterError.onError = null;
    super.dispose();
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.stackTrace,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[600],
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We encountered an unexpected error. Please try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Error Details (Debug)'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error: ${error.toString()}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          if (stackTrace != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'StackTrace: ${stackTrace.toString()}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Retry mechanism with exponential backoff
class RetryMechanism {
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int retryCount = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount > maxRetries) {
          rethrow;
        }

        // Exponential backoff
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }
  }
}

// Error handling utility
class ErrorHandler {
  static void handleError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace, {
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    if (kDebugMode) {
      debugPrint('Error: $error');
      debugPrint('StackTrace: $stackTrace');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: Text(message ?? 'An unexpected error occurred. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    BuildContext? context,
    String? errorTitle,
    String? errorMessage,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (context != null) {
        handleError(
          context,
          e,
          stackTrace,
          title: errorTitle,
          message: errorMessage,
        );
      }
      return null;
    }
  }
}

// Global error boundary for the entire app
class GlobalErrorBoundary extends StatelessWidget {
  final Widget child;

  const GlobalErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: () {
        // Log error to analytics or crash reporting service
        debugPrint('Global error occurred');
      },
      child: child,
    );
  }
} 