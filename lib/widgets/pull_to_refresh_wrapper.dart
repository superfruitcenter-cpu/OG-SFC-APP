import 'package:flutter/material.dart';

class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String refreshMessage;

  const PullToRefreshWrapper({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.refreshMessage = 'Refreshing...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(refreshMessage),
              ],
            ),
            duration: const Duration(milliseconds: 1000),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        await onRefresh();
      },
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 3,
      child: child,
    );
  }
}

