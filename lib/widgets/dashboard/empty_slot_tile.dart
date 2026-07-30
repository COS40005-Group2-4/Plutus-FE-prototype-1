import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// "+" tile shown in unused dashboard grid cells while edit mode is
/// active. Tapping opens the add-widget sheet (the parent owns the
/// callback wiring).
///
/// Visual: dashed hairline outline, muted "+" glyph, gold "Add widget"
/// label below (the tile's one legible affordance). Kept as a single
/// Material so the entire surface is one large tap target.
class EmptySlotTile extends StatelessWidget {
  final VoidCallback onTap;

  const EmptySlotTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.editModeEmptySlotLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          hoverColor: t.goldWeak,
          highlightColor: t.goldWeak,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Dashed hairline outline.
              CustomPaint(
                painter: _DashedRectPainter(
                  color: t.border,
                  strokeWidth: 1.5,
                  radius: AppRadius.lg,
                ),
              ),
              // Centred "+" + label.
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.add_rounded,
                      size: 24,
                      color: t.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.editModeEmptySlotLabel,
                      style: AppTextStyles.labelStyle.copyWith(
                        color: t.goldText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  static const double dashLength = 6;
  static const double gapLength = 4;

  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(
            distance,
            next.clamp(0, metric.length).toDouble(),
          ),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}
