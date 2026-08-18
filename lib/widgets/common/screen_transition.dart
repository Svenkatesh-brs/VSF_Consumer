import 'package:flutter/material.dart';

enum ContentTransitionDirection {
  fromLeft,
  fromRight,
}

class ScreenContentTransition extends StatefulWidget {
  const ScreenContentTransition({
    super.key,
    required this.child,
    required this.direction,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final ContentTransitionDirection direction;

  /// Delay before this particular element starts moving.
  ///
  /// Example:
  /// Duration.zero       -> first element
  /// 100 milliseconds    -> second element
  /// 200 milliseconds    -> third element
  final Duration delay;

  final Duration duration;
  final Curve curve;

  @override
  State<ScreenContentTransition> createState() =>
      _ScreenContentTransitionState();
}

class _ScreenContentTransitionState
    extends State<ScreenContentTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  /// Tracks the last known [TickerMode] state. When a pushed opaque route is
  /// popped, tickers are re-enabled for the restored route; we use that as a
  /// signal that the screen became visible again so we can replay the entrance.
  bool _wasTickerEnabled = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final beginOffset =
        widget.direction == ContentTransitionDirection.fromLeft
            ? const Offset(-1.2, 0)
            : const Offset(1.2, 0);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _startAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isEnabled = TickerMode.valuesOf(context).enabled;

    if (!_wasTickerEnabled && isEnabled) {
      _restartAnimation();
    }

    _wasTickerEnabled = isEnabled;
  }

  Future<void> _startAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }

    if (!mounted) {
      return;
    }

    _controller.forward();
  }

  Future<void> _restartAnimation() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }

    if (!mounted) {
      return;
    }

    _controller
      ..reset()
      ..forward();
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