import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.showWatermark = true,
    this.watermarkHeroTag,
  });

  final Widget child;
  final bool showWatermark;
  final String? watermarkHeroTag;

  Widget get _watermark => Center(
        child: IgnorePointer(
          child: Image.asset(
            AppConstants.watermarkAsset,
            width: AppConstants.watermarkWidth,
            opacity: const AlwaysStoppedAnimation(
              AppConstants.watermarkOpacity,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fullSize = MediaQuery.of(context).size;

    Widget? watermark;

    if (showWatermark) {
      watermark = _watermark;

      if (watermarkHeroTag != null) {
        watermark = Hero(
          tag: watermarkHeroTag!,
          child: watermark,
        );
      }
    }

    Widget fixedLayer(Widget widget) {
      return Positioned.fill(
        child: OverflowBox(
          minWidth: fullSize.width,
          maxWidth: fullSize.width,
          minHeight: fullSize.height,
          maxHeight: fullSize.height,
          alignment: Alignment.topCenter,
          child: widget,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        fixedLayer(
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage(
                  AppConstants.backgroundAsset,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (watermark != null)
          fixedLayer(
            IgnorePointer(
              child: watermark,
            ),
          ),
        child,
      ],
    );
  }
}