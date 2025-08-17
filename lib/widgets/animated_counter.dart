import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final int count;
  final Duration duration;
  final TextStyle? textStyle;

  const AnimatedCounter({
    Key? key,
    required this.count,
    this.duration = const Duration(milliseconds: 300),
    this.textStyle,
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _previousCount = widget.count;
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _previousCount = oldWidget.count;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _animation.value),
          child: Text(
            widget.count.toString(),
            style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

