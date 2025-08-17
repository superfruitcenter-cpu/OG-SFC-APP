import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_service.dart';

class OfflineIndicator extends StatelessWidget {
  final bool showText;
  final bool showBanner;
  final VoidCallback? onRetry;

  const OfflineIndicator({
    super.key,
    this.showText = true,
    this.showBanner = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        if (!offlineService.isInitialized) {
          return const SizedBox.shrink();
        }

        if (!offlineService.isOnline) {
          if (showBanner) {
            return _OfflineBanner(onRetry: onRetry);
          }
          return _OfflineChip(showText: showText, onRetry: onRetry);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const _OfflineBanner({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Some features may not be available.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfflineChip extends StatelessWidget {
  final bool showText;
  final VoidCallback? onRetry;

  const _OfflineChip({
    required this.showText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off,
            size: 16,
            color: Colors.white,
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            const Text(
              'Offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRetry,
              child: const Icon(
                Icons.refresh,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Offline-aware app bar
class OfflineAwareAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool showOfflineIndicator;
  final VoidCallback? onRetry;

  const OfflineAwareAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.showOfflineIndicator = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (showOfflineIndicator) ...[
            const SizedBox(width: 8),
            OfflineIndicator(showText: false, onRetry: onRetry),
          ],
        ],
      ),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Offline-aware bottom navigation bar
class OfflineAwareBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int>? onTap;
  final bool showOfflineIndicator;

  const OfflineAwareBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
    this.showOfflineIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showOfflineIndicator && !offlineService.isOnline)
              _OfflineBanner(),
            BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: offlineService.isOnline ? onTap : null,
              items: items,
              type: BottomNavigationBarType.fixed,
            ),
          ],
        );
      },
    );
  }
}

// Offline-aware floating action button
class OfflineAwareFloatingActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool showOfflineIndicator;

  const OfflineAwareFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.showOfflineIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        return FloatingActionButton(
          onPressed: offlineService.isOnline ? onPressed : null,
          tooltip: tooltip,
          child: this.child,
        );
      },
    );
  }
}

// Offline status overlay
class OfflineStatusOverlay extends StatelessWidget {
  final Widget child;
  final bool showOverlay;

  const OfflineStatusOverlay({
    super.key,
    required this.child,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        if (!showOverlay || offlineService.isOnline) {
          return this.child;
        }

        return Stack(
          children: [
            this.child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _OfflineBanner(),
            ),
          ],
        );
      },
    );
  }
}

// Offline-aware drawer
class OfflineAwareDrawer extends StatelessWidget {
  final Widget child;
  final bool showOfflineIndicator;

  const OfflineAwareDrawer({
    super.key,
    required this.child,
    this.showOfflineIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineService>(
      builder: (context, offlineService, child) {
        if (!showOfflineIndicator || offlineService.isOnline) {
          return this.child;
        }

        return Column(
          children: [
            _OfflineBanner(),
            Expanded(child: this.child),
          ],
        );
      },
    );
  }
} 