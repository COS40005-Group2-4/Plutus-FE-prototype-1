import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final double borderRadius;
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
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.borderOpacity = 0.2,
    this.opacity = 0.1,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.shape = BoxShape.rectangle,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: isDark ? 20 : 16,
            spreadRadius: isDark ? 2 : 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape == BoxShape.circle 
            ? BorderRadius.circular(1000) 
            : BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1A3A4A).withValues(alpha: opacity + 0.15)
                  : (color ?? Colors.white).withValues(alpha: opacity),
              shape: shape,
              borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: isDark 
                    ? const Color(0xFF2A5470).withValues(alpha: borderOpacity + 0.1)
                    : Colors.white.withValues(alpha: borderOpacity),
                width: 1.0,
              ),
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [
                  const Color(0xFF1E4A5F).withValues(alpha: opacity + 0.2),
                  const Color(0xFF132D3F).withValues(alpha: opacity + 0.15),
                ] : [
                  (color ?? Colors.white).withValues(alpha: opacity + 0.1),
                  (color ?? Colors.white).withValues(alpha: opacity),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
