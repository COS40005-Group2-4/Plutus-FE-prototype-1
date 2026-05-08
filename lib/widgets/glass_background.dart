import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// App-wide background. Despite the legacy "Glass" name, this now renders a
/// clean, adaptive surface with a single soft accent wash for depth — no
/// heavy gradients or coloured orbs.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color base = AppColors.background(brightness);
    final Color accent = AppColors.brand(brightness)
        .withValues(alpha: isDark ? 0.10 : 0.06);

    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: base)),
        // Single, calm accent wash in the upper area for visual interest.
        Positioned(
          top: -180,
          right: -120,
          child: IgnorePointer(
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[accent, Colors.transparent],
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
