import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.showWatermark = true,
    this.watermarkHeroTag,
    this.showBottomImage = false,
  });

  final Widget child;
  final bool showWatermark;
  final String? watermarkHeroTag;
  final bool showBottomImage;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget? watermark;

    if (showWatermark) {
      watermark = Center(
        child: IgnorePointer(
          child: Image.asset(
            'assets/vsf.png',
            width: 260,
            opacity: const AlwaysStoppedAnimation(0.06),
          ),
        ),
      );

      if (watermarkHeroTag != null) {
        watermark = Hero(
          tag: watermarkHeroTag!,
          child: watermark,
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // --------------------------------------------------------
        // BASE BACKGROUND
        // --------------------------------------------------------
        Positioned.fill(
          child: Image.asset(
            'assets/bg.png',
            fit: BoxFit.cover,
          ),
        ),

        // --------------------------------------------------------
        // OPTIONAL WATERMARK
        // --------------------------------------------------------
        if (watermark != null)
          Positioned.fill(
            child: IgnorePointer(
              child: watermark,
            ),
          ),

        // --------------------------------------------------------
        // APP BOTTOM DECORATION
        // --------------------------------------------------------
        if (showBottomImage)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/appbg.png',
                width: size.width,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

        // --------------------------------------------------------
        // SCREEN CONTENT
        // --------------------------------------------------------
        child,
      ],
    );
  }
}