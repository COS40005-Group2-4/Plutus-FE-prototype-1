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
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 4,
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
              color: (color ?? Colors.white).withValues(alpha: opacity),
              shape: shape,
              borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: Colors.white.withValues(alpha: borderOpacity),
                width: 1.5,
              ),
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
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
