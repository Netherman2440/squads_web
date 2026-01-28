import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:app/core/app_config.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < AppConfig.mobileWidth;
    final brandStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      fontFamily: theme.textTheme.bodyLarge?.fontFamily,
      color: theme.colorScheme.onSurface,
    );
    final span = TextSpan(
      style: brandStyle,
      children: [
        const TextSpan(text: 'pick'),
        TextSpan(
          text: 'teams',
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        const TextSpan(text: '.pl'),
      ],
    );
    final textPainter = TextPainter(
      text: span,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    final logoWidth = textPainter.size.width > 0
        ? textPainter.size.width
        : math.min(maxWidth, 180);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isNarrow) ...[
          Image.asset(
            'assets/icons/logo.png',
            width: logoWidth.toDouble(),
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 36),
        ],
        Text.rich(span, textAlign: TextAlign.center),
      ],
    );
  }
}
