import 'package:flutter/material.dart';
import '../../theme/plutus_tokens.dart';

/// Greek-key (meander) hairline divider (spec §6). At arm's length it
/// reads as a divider; up close, the motif. One unit is picked out in
/// gold so the detail is discoverable, never loud.
class MeanderDivider extends StatelessWidget {
  final double height;

  const MeanderDivider({super.key, this.height = 10});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MeanderPainter(
          lineColor: t.border,
          accentColor: t.gold.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _MeanderPainter extends CustomPainter {
  final Color lineColor;
  final Color accentColor;

  const _MeanderPainter({required this.lineColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double unit = 14;
    final double y0 = size.height;
    final int units = (size.width / unit).floor();
    if (units < 1) return;
    // Center the pattern; pick the gold unit just left of center.
    final double startX = (size.width - units * unit) / 2;
    final int goldIndex = (units / 2).floor() - 1;

    for (int i = 0; i < units; i++) {
      final double x = startX + i * unit;
      final Paint paint = Paint()
        ..color = i == goldIndex ? accentColor : lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final Path p = Path()
        ..moveTo(x, y0)
        ..lineTo(x, 0)
        ..lineTo(x + unit * 0.55, 0)
        ..lineTo(x + unit * 0.55, y0 * 0.55)
        ..lineTo(x + unit * 0.25, y0 * 0.55)
        ..moveTo(x + unit * 0.55, 0)
        ..lineTo(x + unit, 0)
        ..lineTo(x + unit, y0);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeanderPainter old) =>
      old.lineColor != lineColor || old.accentColor != accentColor;
}
