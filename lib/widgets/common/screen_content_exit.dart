import 'package:flutter/material.dart';

enum ContentExitDirection {
  toLeft,
  toRight,
}

class ScreenContentExit extends StatefulWidget {
  const ScreenContentExit({
    super.key,
    required this.child,
    required this.isExiting,
    required this.direction,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.resetDelay,
    this.curve = Curves.easeInOutCubic,
  });

  final Widget child;

  /// Starts the exit animation when true.
  final bool isExiting;

  /// toLeft  -> content moves out to the left.
  /// toRight -> content moves out to the right.
  final ContentExitDirection direction;

  /// Delay before this particular element starts exiting.
  final Duration delay;

  /// Delay before the content is restored to its resting spot when
  /// [isExiting] goes back to false (e.g. after a pushed screen is popped).
  /// Defaults to [delay]. Should match the paired entrance transition's delay
  /// so the content stays hidden until that entrance animation begins.
  final Duration? resetDelay;

  final Duration duration;
  final Curve curve;

  @override
  State<ScreenContentExit> createState() =>
      _ScreenContentExitState();
}

class _ScreenContentExitState
    extends State<ScreenContentExit> {
  bool _shouldExit = false;

  /// Kept separately from [ScreenContentExit.duration] so the reset that
  /// happens when a pushed screen pops back can jump instantly instead of
  /// sliding the content back to its resting spot.
  late Duration _effectiveDuration;

  /// Guards against a stale delayed reset firing after a new exit has already
  /// started (e.g. the user immediately re-opens loan details).
  int _animationToken = 0;

  @override
  void initState() {
    super.initState();

    _shouldExit = widget.isExiting;
    _effectiveDuration = widget.duration;
  }

  @override
  void didUpdateWidget(
    covariant ScreenContentExit oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isExiting && widget.isExiting) {
      _effectiveDuration = widget.duration;
      _startExit();
    } else if (oldWidget.isExiting && !widget.isExiting) {
      _resetExit();
    }
  }

  Future<void> _startExit() async {
    final token = ++_animationToken;

    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }

    if (!mounted || token != _animationToken) {
      return;
    }

    setState(() {
      _shouldExit = true;
    });
  }

  /// Restores the content to its resting spot only after the same stagger
  /// delay used by the paired entrance transition. Keeping the content hidden
  /// until then prevents a flash of the full content sitting at its final
  /// position before the entrance animation begins.
  Future<void> _resetExit() async {
    final token = ++_animationToken;

    final delay = widget.resetDelay ?? widget.delay;

    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    if (!mounted || token != _animationToken) {
      return;
    }

    setState(() {
      _effectiveDuration = Duration.zero;
      _shouldExit = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exitOffset =
        widget.direction == ContentExitDirection.toLeft
            ? const Offset(-1.2, 0)
            : const Offset(1.2, 0);

    return AnimatedSlide(
      offset: _shouldExit ? exitOffset : Offset.zero,
      duration: _effectiveDuration,
      curve: widget.curve,
      child: AnimatedOpacity(
        opacity: _shouldExit ? 0.0 : 1.0,
        duration: _effectiveDuration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}