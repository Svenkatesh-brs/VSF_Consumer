import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class LoanQuickActions extends StatefulWidget {
  final VoidCallback? onTransactionsTap;
  final VoidCallback? onContactUpdateTap;
  final VoidCallback? onComplaintsTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onEmiScheduleTap;

  const LoanQuickActions({
    super.key,
    this.onTransactionsTap,
    this.onContactUpdateTap,
    this.onComplaintsTap,
    this.onHelpTap,
    this.onEmiScheduleTap,
  });

  @override
  State<LoanQuickActions> createState() => _LoanQuickActionsState();
}

class _LoanQuickActionsState extends State<LoanQuickActions>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _floatController;
  late final AnimationController _hintController;

  late final ScrollController _scrollController;

  bool _showScrollHint = true;
  bool _hasUserScrolled = false;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(_handleScroll);

    // ==========================================================
    // ENTRY ANIMATION
    // ==========================================================

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // ==========================================================
    // SUBTLE FLOATING ANIMATION
    // ==========================================================

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // ==========================================================
    // HORIZONTAL SCROLL HINT
    // ==========================================================

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _entryController.forward();

    // Give the dock time to appear before showing the hint.
    Future.delayed(const Duration(milliseconds: 950), _playScrollHint);
  }

  // ============================================================
  // SCROLL LISTENER
  // ============================================================

  void _handleScroll() {
    if (!_hasUserScrolled &&
        _scrollController.hasClients &&
        _scrollController.offset > 4) {
      _hasUserScrolled = true;

      if (mounted) {
        setState(() {
          _showScrollHint = false;
        });
      }

      _hintController.stop();
    }

    // Hide arrow when the user reaches the end.
    if (_scrollController.hasClients &&
        _scrollController.position.atEdge &&
        _scrollController.offset > 0) {
      if (_showScrollHint && mounted) {
        setState(() {
          _showScrollHint = false;
        });
      }
    }
  }

  // ============================================================
  // PLAY ONE-TIME SCROLL HINT
  // ============================================================

  Future<void> _playScrollHint() async {
    if (!mounted || _hasUserScrolled || !_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.maxScrollExtent <= 0) {
      return;
    }

    await _hintController.forward();

    if (!mounted || _hasUserScrolled || !_scrollController.hasClients) {
      return;
    }

    // Tiny movement to reveal that the content is scrollable.
    await _scrollController.animateTo(
      18,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
    );

    if (!mounted || _hasUserScrolled || !_scrollController.hasClients) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted || _hasUserScrolled || !_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
    );

    if (mounted && !_hasUserScrolled) {
      setState(() {
        _showScrollHint = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);

    _scrollController.dispose();
    _entryController.dispose();
    _floatController.dispose();
    _hintController.dispose();

    super.dispose();
  }

  // ============================================================
  // ACTION DATA
  // ============================================================

  List<_QuickActionData> get _actions {
    return [
      _QuickActionData(
        title: 'EMI Schedule',
        icon: Icons.event_note_outlined,
        color: const Color(0xFF258F92),
        onTap: widget.onEmiScheduleTap,
      ),
      _QuickActionData(
        title: 'Transactions',
        icon: Icons.swap_vert_rounded,
        color: const Color(0xFF3158B8),
        onTap: widget.onTransactionsTap,
      ),
      _QuickActionData(
        title: 'Contact Update',
        icon: Icons.contact_phone_outlined,
        color: const Color(0xFF6956C8),
        onTap: widget.onContactUpdateTap,
      ),
      _QuickActionData(
        title: 'Complaints',
        icon: Icons.report_problem_outlined,
        color: const Color(0xFFD8893F),
        onTap: widget.onComplaintsTap,
      ),
      _QuickActionData(
        title: 'Help',
        icon: Icons.help_outline_rounded,
        color: const Color(0xFF268B68),
        onTap: widget.onHelpTap,
      ),
    ];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Everything you need, at a glance',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.black45,
          ),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // DOCK
        // ========================================================
        SizedBox(
          height: 100,
          child: Stack(
            children: [
              // ==================================================
              // HORIZONTAL ACTION LIST
              // ==================================================

              ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 2,
                  right: 30,
                  top: 4,
                  bottom: 4,
                ),
                itemCount: _actions.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 4);
                },
                itemBuilder: (context, index) {
                  final action = _actions[index];

                  return _FloatingActionItem(
                    data: action,
                    index: index,
                    entryController: _entryController,
                    floatController: _floatController,
                  );
                },
              ),

              // ==================================================
              // RIGHT EDGE FADE
              // ==================================================
              IgnorePointer(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _showScrollHint ? 1 : 0,
                    child: Container(
                      width: 42,
                      height: 92,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.transparent, Colors.white],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ==================================================
              // ANIMATED RIGHT ARROW
              // ==================================================
              Positioned(
                right: 2,
                top: 35,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _showScrollHint ? 1 : 0,
                    child: AnimatedBuilder(
                      animation: _hintController,
                      builder: (context, child) {
                        final movement =
                            math.sin(_hintController.value * math.pi * 2) * 3;

                        return Transform.translate(
                          offset: Offset(movement, 0),
                          child: Container(
                            width: 25,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lightBlue.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.lightBlue,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// ACTION DATA
// ==================================================================

class _QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ==================================================================
// FLOATING ACTION ITEM
// ==================================================================

class _FloatingActionItem extends StatefulWidget {
  final _QuickActionData data;
  final int index;
  final AnimationController entryController;
  final AnimationController floatController;

  const _FloatingActionItem({
    required this.data,
    required this.index,
    required this.entryController,
    required this.floatController,
  });

  @override
  State<_FloatingActionItem> createState() => _FloatingActionItemState();
}

class _FloatingActionItemState extends State<_FloatingActionItem> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.data.onTap == null || !mounted) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = (0.08 + (widget.index * 0.08)).clamp(0.0, 0.70);

    final end = (start + 0.30).clamp(0.0, 1.0);

    final bool isDisabled = widget.data.onTap == null;

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.entryController,
        widget.floatController,
      ]),
      builder: (context, child) {
        final float =
            math.sin(widget.floatController.value * math.pi * 2) * 1.4;

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: widget.entryController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
          child: Transform.translate(
            offset: Offset(0, float),
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
              onTap: widget.data.onTap,
              child: AnimatedScale(
                scale: _isPressed ? 0.93 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ==================================================
                      // ICON
                      // ==================================================

                      // ==================================================
                      // PREMIUM COLORFUL BUBBLE
                      // ==================================================
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: _isPressed ? 54 : 50,
                        height: _isPressed ? 54 : 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          // Clean PhonePe-style colorful icon background
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.data.color,
                              widget.data.color.withValues(alpha: 0.78),
                            ],
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: widget.data.color.withValues(
                                alpha: _isPressed ? 0.32 : 0.18,
                              ),
                              blurRadius: _isPressed ? 14 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Center(
                          child: Icon(
                            widget.data.icon,
                            size: _isPressed ? 23 : 21,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // ==================================================
                      // LABEL
                      // ==================================================
                      Text(
                        widget.data.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? AppColors.lightBlue.withValues(alpha: 0.40)
                              : AppColors.lightBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
