import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _lottieController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;

  bool _lottieCompleted = false;
  bool _minimumDurationCompleted = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ------------------------------------------------------------
    // LOGO ANIMATION
    // ------------------------------------------------------------

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Fade:
    // 0% - 25%   : Fade in
    // 25% - 75%  : Stay visible
    // 75% - 100% : Fade out
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_logoController);

    // Scale:
    // 0% - 30%   : 0.75 → 1.05
    // 30% - 75%  : 1.05 → 1.0
    // 75% - 100% : 1.0 → 0.90
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.75,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.90,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_logoController);

    // Slide:
    // Logo starts slightly lower and moves into position.
    _logoSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.0, 0.15),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<Offset>(Offset.zero), weight: 70),
    ]).animate(_logoController);

    _logoController.forward();

    // ------------------------------------------------------------
    // LOTTIE ANIMATION
    // ------------------------------------------------------------

    _lottieController = AnimationController(vsync: this);

    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lottieCompleted = true;
        _tryNavigateToLogin();
      }
    });
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  void _tryNavigateToLogin() {
    if (!_lottieCompleted ||
        !_minimumDurationCompleted ||
        _navigated ||
        !mounted) {
      return;
    }

    _navigated = true;

    Get.offNamed(AppRoutes.login);
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _logoController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ------------------------------------------------
                // VSF LOGO
                // ------------------------------------------------
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/vsf.png',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // BIKE LOTTIE ANIMATION
                // ------------------------------------------------
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Lottie.asset(
                    'assets/animations/splash_animation.json',
                    controller: _lottieController,
                    fit: BoxFit.contain,
                    repeat: false,
                    onLoaded: (composition) {
                      _lottieController
                        ..duration = composition.duration
                        ..forward();

                      // Ensure the splash doesn't finish too quickly.
                      final minimumDuration =
                          composition.duration >
                              const Duration(milliseconds: 2400)
                          ? composition.duration
                          : const Duration(milliseconds: 2400);

                      Future.delayed(minimumDuration, () {
                        if (!mounted) return;

                        _minimumDurationCompleted = true;
                        _tryNavigateToLogin();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
