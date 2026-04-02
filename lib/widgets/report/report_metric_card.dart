import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../widgets/glass_container.dart';

class ReportMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? changeText;
  final Color? changeColor;
  final Color accentColor;

  const ReportMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.changeText,
    this.changeColor,
    this.accentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: Colors.white,
      opacity: 0.05,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          if (changeText != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              changeText!,
              style: TextStyle(
                fontSize: 11,
                color: changeColor ?? Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
