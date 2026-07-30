import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'animated_theme_scope.dart';

/// App-wide background. Despite the legacy "Glass" name, this paints the
/// canvas + a soft brand-tinted wash for ambient depth — magenta on light,
/// violet on dark.
@Deprecated('Use AppCanvas (lib/widgets/core/app_canvas.dart). Removed in PR4.')
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // When AnimatedThemeScope is mid-tween, lerp the brightness-keyed colors
    // ourselves so the canvas doesn't snap at t=0.5. Otherwise this is
    // equivalent to reading Theme.of(context).brightness directly.
    final BrightnessBlend? blend = BrightnessBlend.maybeOf(context);
    final Brightness brightness =
        blend?.to ?? Theme.of(context).brightness;

    Color paletteFor(Color Function(Brightness) keyed) =>
        blend?.lerpColor(keyed) ?? keyed(brightness);

    final Color base = paletteFor(AppColors.background);
    final Color brandWash = paletteFor((Brightness b) => AppColors.brand(b)
        .withValues(alpha: b == Brightness.dark ? 0.18 : 0.10));
    final Color secondaryWash = paletteFor((Brightness b) =>
        b == Brightness.dark
            ? AppColors.primaryStrongDark.withValues(alpha: 0.14)
            : AppColors.accent.withValues(alpha: 0.12));

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
