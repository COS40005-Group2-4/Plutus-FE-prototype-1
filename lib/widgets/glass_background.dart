import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// App-wide background. Despite the legacy "Glass" name, this paints the
/// canvas + a soft brand-tinted wash for ambient depth — magenta on light,
/// violet on dark.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color base = AppColors.background(brightness);
    final Color brandWash = AppColors.brand(brightness)
        .withValues(alpha: isDark ? 0.18 : 0.10);
    final Color secondaryWash = isDark
        ? AppColors.primaryStrongDark.withValues(alpha: 0.14)
        : AppColors.accent.withValues(alpha: 0.12);

    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: base)),
        // Top-right brand wash (magenta/violet).
        Positioned(
          top: -260,
          right: -180,
          child: IgnorePointer(
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[brandWash, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Bottom-left secondary wash (sunshine on light, deep violet on dark)
        // for warmth without competing with widget cards.
        Positioned(
          bottom: -220,
          left: -160,
          child: IgnorePointer(
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[secondaryWash, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
