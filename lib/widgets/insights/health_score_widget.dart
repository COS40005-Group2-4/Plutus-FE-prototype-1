import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_notifier.dart';
import '../../models/ai/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../glass_container.dart';

class HealthScoreWidget extends ConsumerStatefulWidget {
  const HealthScoreWidget({super.key});

  @override
  ConsumerState<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends ConsumerState<HealthScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int _previousScore = 0;
  int _targetScore = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateToScore(int score) {
    if (score == _targetScore && _animController.isCompleted) return;
    _previousScore = _targetScore;
    _targetScore = score;
    _animation = Tween<double>(
      begin: _previousScore.toDouble(),
      end: _targetScore.toDouble(),
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final InsightsState provider = ref.watch(insightsNotifierProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final HealthScore? score = provider.healthScore;

    if (score != null) {
      // Schedule animation after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateToScore(score.score);
      });
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/insights'),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.card,
        opacity: 0.08,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.insightsHealthScore,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: l10n.widgetHelpHealthScore,
                  child: Icon(
                    Icons.help_outline,
                    size: 14,
                    color: AppColors.textTertiary(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: provider.isGenerating
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : score == null
                      ? Center(
                          child: Text(
                            l10n.insightsHealthScoreEmpty,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: AnimatedBuilder(
                                animation: _animation,
                                builder: (BuildContext context, Widget? child) {
                                  final int animatedScore = _animation.value.round();
                                  return CustomPaint(
                                    painter: _ScoreArcPainter(
                                      score: animatedScore,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.1),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$animatedScore',
                                            style: TextStyle(
                                              fontSize: (provider.insightsFontSize + 14).clamp(20.0, 38.0),
                                              fontWeight: FontWeight.bold,
                                              color: _scoreColor(animatedScore),
                                            ),
                                          ),
                                          if (score.previousScore != null)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  score.score >= score.previousScore!
                                                      ? Icons.arrow_upward
                                                      : Icons.arrow_downward,
                                                  size: 12,
                                                  color: score.score >= score.previousScore!
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                ),
                                                Text(
                                                  '${(score.score - score.previousScore!).abs()}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: score.score >= score.previousScore!
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              score.summary,
                              style: TextStyle(
                                fontSize: (provider.insightsFontSize - 2).clamp(10.0, 16.0),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

class _ScoreArcPainter extends CustomPainter {
  final int score;
  final Color backgroundColor;

  _ScoreArcPainter({required this.score, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const double startAngle = math.pi * 0.75;
    const double fullSweep = math.pi * 1.5;
    final double sweepAngle = fullSweep * (score / 100).clamp(0.0, 1.0);

    // Background arc
    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(8), startAngle, fullSweep, false, bgPaint);

    // Score arc
    final Color scoreColor;
    if (score >= 75) {
      scoreColor = AppColors.success;
    } else if (score >= 50) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.error;
    }

    final Paint scorePaint = Paint()
      ..color = scoreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(8), startAngle, sweepAngle, false, scorePaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
