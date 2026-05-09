import 'dart:async';
import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../services/interfaces/i_investment_service.dart';
import '../services/settings_service.dart';
import '../di/service_locator.dart';
import '../l10n/app_localizations.dart';

class RoiWidget extends StatefulWidget {
  const RoiWidget({super.key});

  @override
  State<RoiWidget> createState() => _RoiWidgetState();
}

class _RoiWidgetState extends State<RoiWidget> with AutomaticKeepAliveClientMixin {
  double _roiValue = 0.0;
  bool _isLoading = true;
  StreamSubscription<void>? _changeSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRoiData();
    _changeSub = sl<IInvestmentService>().onChanged.listen((_) {
      _loadRoiData();
    });
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadRoiData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String currency = 'VND';
      try {
        final settingsService = SettingsService();
        currency = await settingsService.getDefaultCurrency(1);
      } catch (_) {}

      final investmentService = sl<IInvestmentService>();
      final data = await investmentService.getInvestmentReport(currency: currency);

      if (mounted) {
        setState(() {
          _roiValue = (data['roi'] as num?)?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ROI: $e');
      if (mounted) {
        setState(() {
          _roiValue = 0.0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final isPositive = _roiValue >= 0;
    final valueColor = _roiValue == 0
        ? AppColors.textSecondary(brightness)
        : isPositive
            ? AppColors.positive(brightness)
            : AppColors.negative(brightness);
    final trendIcon = _roiValue == 0
        ? Icons.trending_flat
        : isPositive
            ? Icons.trending_up
            : Icons.trending_down;

    return GlassContainer(
      borderRadius: AppRadius.card,
      opacity: 0.08,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 150;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header row: label + info tooltip
              Row(
                children: [
                  Icon(Icons.show_chart, size: 16,
                      color: AppColors.textSecondary(brightness)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.roi,
                    style: TextStyle(
                      color: AppColors.textSecondary(brightness),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: l10n.widgetHelpRoi,
                    child: Icon(Icons.help_outline, size: 14,
                        color: AppColors.textTertiary(brightness)),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),

              // Big number + trend arrow
              _isLoading
                  ? SizedBox(
                      height: isCompact ? 28 : 36,
                      child: const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Icon(trendIcon, size: isCompact ? 22 : 28,
                            color: valueColor),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            '${isPositive && _roiValue != 0 ? '+' : ''}${_roiValue.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: valueColor,
                              fontSize: isCompact ? 22 : 28,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isCompact ? 2 : AppSpacing.xs),

              // Subtitle
              Text(
                l10n.currentRoi,
                style: TextStyle(
                  color: AppColors.textTertiary(brightness),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}
