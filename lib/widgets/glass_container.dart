import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';

/// Card surface used throughout the app. Despite the legacy "Glass" name,
/// this now renders a clean, flat surface with a brand-tinted shadow halo —
/// no backdrop blur.
///
/// Behaviour by parameter:
/// - `color` null: standard themed surface (white on light, navy card on dark).
/// - `color` non-null + `opacity < 1`: the surface is the themed surface
///   *blended with* the accent color at `opacity` — produces a soft tinted
///   card that harmonises with the new design language. This is how the
///   dashboard widget cards (profile, budget, etc.) get their accent color.
/// - `color` non-null + `opacity == 1`: the accent is used as the literal
///   fill (rare; mainly for solid-fill banners).
class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
  // Legacy parameters — accepted for backwards compatibility.
  final double blur;
  final double borderOpacity;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final BoxShape shape;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.borderRadius = AppRadius.card,
    this.blur = 0.0,
    this.borderOpacity = 1.0,
    this.opacity = 1.0,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.shape = BoxShape.rectangle,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color baseSurface = AppColors.surface(brightness);

    // Resolve the fill: if an accent color is supplied with a fractional
    // opacity, render a tinted card; otherwise use the raw surface or the
    // raw accent (full-fill mode).
    final Color resolvedSurface;
    if (color != null && opacity < 1.0) {
      // Soft tint: blend (color × opacity) over the themed base surface.
      resolvedSurface = Color.alphaBlend(
        color!.withValues(alpha: opacity.clamp(0.0, 1.0)),
        baseSurface,
      );
    } else {
      resolvedSurface = color ?? baseSurface;
    }

    final BorderRadius? radius = shape == BoxShape.circle
        ? null
        : BorderRadius.circular(borderRadius);

    // Dark mode adds a subtle white@6% hairline so tinted cards still
    // separate from the canvas. Light mode relies on the brand-glow halo.
    final BoxBorder? defaultBorder = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1)
        : null;

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? resolvedSurface : null,
        gradient: gradient,
        shape: shape,
        borderRadius: radius,
        border: border ?? defaultBorder,
        boxShadow: AppElevation.brandGlow(brightness),
      ),
      child: child,
    );
  }
}
