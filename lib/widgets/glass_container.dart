import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';

/// Card surface used throughout the app. Despite the legacy "Glass" name,
/// this now renders a clean, flat surface with a hairline border and
/// subtle elevation — no backdrop blur or translucency.
///
/// Existing call-sites pass legacy parameters (`blur`, `opacity`,
/// `borderOpacity`, `gradient`); they are accepted for compatibility but
/// no longer affect rendering, so the whole app picks up the new visual
/// language without per-call-site edits.
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
    this.borderRadius = AppRadius.lg,
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
    final Color surface = color ?? AppColors.surface(brightness);
    final Color borderColor = AppColors.border(brightness);

    final BorderRadius? radius = shape == BoxShape.circle
        ? null
        : BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        gradient: gradient,
        shape: shape,
        borderRadius: radius,
        border: border ??
            Border.all(color: borderColor, width: 1),
        boxShadow: AppElevation.low(brightness),
      ),
      child: child,
    );
  }
}
