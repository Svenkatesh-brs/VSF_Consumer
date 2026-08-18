import 'package:flutter/material.dart';

class DirectionalAnimation extends StatefulWidget {
  const DirectionalAnimation({
    super.key,
    required this.child,
    required this.beginOffset,
    this.delay = 0.0,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;

  /// Use:
  /// Offset(-1.2, 0) → enters from left
  /// Offset(1.2, 0)  → enters from right
  final Offset beginOffset;

  /// Delay before the animation starts.
  /// Example: 0.10, 0.20, 0.30
  final double delay;

  final Duration duration;

  @override
  State<DirectionalAnimation> createState() =>
      _DirectionalAnimationState();
}

class _DirectionalAnimationState
    extends State<DirectionalAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final start = widget.delay.clamp(0.0, 0.70);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          start,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}