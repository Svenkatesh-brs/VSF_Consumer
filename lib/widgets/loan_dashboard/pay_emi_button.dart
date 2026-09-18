import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class PayEmiButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isCompleted;

  const PayEmiButton({
    super.key,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  State<PayEmiButton> createState() => _PayEmiButtonState();
}

class _PayEmiButtonState extends State<PayEmiButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shineController;
  late final AnimationController _entryController;

  bool _isPressed = false;

  bool get _isDisabled =>
      widget.isCompleted || widget.onTap == null;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // ENTRY
    // ==========================================================

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // ==========================================================
    // BREATHING GLOW
    // ==========================================================

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    // ==========================================================
    // MOVING SHINE
    // ==========================================================

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _entryController.forward();

    if (!_isDisabled) {
      _pulseController.repeat(reverse: true);

      Future.delayed(
        const Duration(milliseconds: 900),
        () {
          if (!mounted || _isDisabled) {
            return;
          }

          _shineController.repeat();
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant PayEmiButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCompleted != oldWidget.isCompleted ||
        widget.onTap != oldWidget.onTap) {
      if (_isDisabled) {
        _pulseController.stop();
        _shineController.stop();
      } else {
        _pulseController.repeat(reverse: true);

        if (!_shineController.isAnimating) {
          _shineController.repeat();
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shineController.dispose();
    _entryController.dispose();

    super.dispose();
  }

  // ============================================================
  // PRESS
  // ============================================================

  void _setPressed(bool value) {
    if (_isDisabled || !mounted) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.86,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: Curves.easeOutBack,
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _shineController,
          ]),
          builder: (context, child) {
            final pulseValue =
                Curves.easeInOut.transform(
              _pulseController.value,
            );

            final shineValue =
                _shineController.value;

            final glowOpacity = _isDisabled
                ? 0.0
                : 0.18 + (pulseValue * 0.12);

            final glowBlur =
                _isPressed ? 8.0 : 20.0 + (pulseValue * 8);

            return AnimatedScale(
              scale: _isPressed ? 0.96 : 1.0,
              duration: const Duration(
                milliseconds: 120,
              ),
              curve: Curves.easeOut,
              child: GestureDetector(
                onTapDown: (_) {
                  _setPressed(true);
                },
                onTapUp: (_) {
                  _setPressed(false);
                },
                onTapCancel: () {
                  _setPressed(false);
                },
                onTap: _isDisabled
                    ? null
                    : widget.onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ==================================================
                    // OUTER GLOW
                    // ==================================================

                    if (!_isDisabled)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.buttonEnd
                                      .withValues(
                                    alpha: glowOpacity,
                                  ),
                                  blurRadius: glowBlur,
                                  spreadRadius:
                                      pulseValue * 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ==================================================
                    // MAIN BUTTON
                    // ==================================================

                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(100),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: _isDisabled
                              ? [
                                  Colors.grey.shade400,
                                  Colors.grey.shade500,
                                ]
                              : const [
                                  AppColors.buttonStart,
                                  AppColors.primary,
                                  AppColors.buttonEnd,
                                ],
                          stops: const [
                            0.0,
                            0.52,
                            1.0,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: _isDisabled
                                ? 0.20
                                : 0.25,
                          ),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _isPressed
                                  ? 0.06
                                  : 0.13,
                            ),
                            blurRadius:
                                _isPressed ? 8 : 18,
                            offset: Offset(
                              0,
                              _isPressed ? 3 : 8,
                            ),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(100),
                        child: Stack(
                          children: [
                            // ==========================================
                            // MOVING SHINE
                            // ==========================================

                            if (!_isDisabled)
                              Positioned(
                                left:
                                    -70 +
                                    (shineValue * 300),
                                top: -20,
                                child: IgnorePointer(
                                  child: Transform.rotate(
                                    angle:
                                        -math.pi / 8,
                                    child: Container(
                                      width: 35,
                                      height: 100,
                                      decoration:
                                          BoxDecoration(
                                        gradient:
                                            LinearGradient(
                                          colors: [
                                            Colors
                                                .transparent,
                                            Colors.white
                                                .withValues(
                                              alpha: 0.24,
                                            ),
                                            Colors
                                                .transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // ==========================================
                            // CONTENT
                            // ==========================================

                            Row(
                              children: [
                                // --------------------------------------
                                // RUPEE ICON
                                // --------------------------------------

                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white
                                        .withValues(
                                      alpha: _isDisabled
                                          ? 0.12
                                          : 0.18,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors
                                          .white
                                          .withValues(
                                        alpha: 0.20,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    _isDisabled
                                        ? Icons
                                            .check_rounded
                                        : Icons
                                            .currency_rupee_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(width: 11),

                                // --------------------------------------
                                // TEXT
                                // --------------------------------------

                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        _isDisabled
                                            ? 'LOAN COMPLETED'
                                            : 'PAY EMI',
                                        style:
                                            const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w800,
                                          letterSpacing: 0.7,
                                          color:
                                              Colors.white,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 2,
                                      ),
                                      Text(
                                        _isDisabled
                                            ? 'No payment required'
                                            : 'Make your payment securely',
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                        style:
                                            TextStyle(
                                          fontSize: 9.5,
                                          fontWeight:
                                              FontWeight.w500,
                                          color: Colors
                                              .white
                                              .withValues(
                                            alpha: 0.68,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // --------------------------------------
                                // ARROW
                                // --------------------------------------

                                AnimatedContainer(
                                  duration:
                                      const Duration(
                                    milliseconds: 180,
                                  ),
                                  width: 42,
                                  height: 42,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white
                                        .withValues(
                                      alpha: _isDisabled
                                          ? 0.10
                                          : 0.16,
                                    ),
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isDisabled
                                        ? Icons
                                            .check_rounded
                                        : Icons
                                            .arrow_forward_rounded,
                                    size: 20,
                                    color:
                                        Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}