import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/plutus_tokens.dart';

/// Calm card surface (spec §5): opaque surface, hairline border,
/// radius 16, low shadow. Replaces the legacy [GlassContainer].
class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final BorderRadius radius = BorderRadius.circular(AppRadius.card);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.componentLg),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: radius,
        border: Border.all(color: t.border),
        boxShadow: t.shadowLow,
      ),
      child: content,
    );
  }
}
