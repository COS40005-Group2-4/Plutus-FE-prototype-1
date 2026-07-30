import 'dart:async';
import 'package:flutter/material.dart';
import 'core/app_card.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
import '../services/interfaces/i_investment_service.dart';
import '../services/settings_service.dart';
import '../di/service_locator.dart';
import '../l10n/app_localizations.dart';

class IrrWidget extends StatefulWidget {
  const IrrWidget({super.key});

  @override
  State<IrrWidget> createState() => _IrrWidgetState();
}

class _IrrWidgetState extends State<IrrWidget> with AutomaticKeepAliveClientMixin {
  double _irrValue = 0.0;
  bool _isLoading = true;
  StreamSubscription<void>? _changeSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadIrrData();
    _changeSub = sl<IInvestmentService>().onChanged.listen((_) {
      _loadIrrData();
    });
  }

  @override
  void dispose() {
    _changeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadIrrData() async {
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
          _irrValue = (data['irr'] as num?)?.toDouble() ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading IRR: $e');
      if (mounted) {
        setState(() {
          _irrValue = 0.0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;
    final isPositive = _irrValue >= 0;
    final valueColor = _irrValue == 0
        ? t.text
        : isPositive
            ? t.success.text
            : t.error.text;
    final trendIcon = _irrValue == 0
        ? Icons.trending_flat
        : isPositive
            ? Icons.trending_up
            : Icons.trending_down;

    return AppCard(
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
                  Icon(Icons.timeline, size: 16,
                      color: t.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.irr,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: l10n.widgetHelpIrr,
                    child: Icon(Icons.help_outline, size: 14,
                        color: t.textMuted),
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
                            '${isPositive && _irrValue != 0 ? '+' : ''}${_irrValue.toStringAsFixed(2)}%',
                            style: AppTextStyles.numericStyle.copyWith(
                              color: valueColor,
                              fontSize: isCompact ? 22 : 28,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: isCompact ? 2 : AppSpacing.xs),

              // Subtitle
              Text(
                l10n.currentIrr,
                style: TextStyle(
                  color: t.textMuted,
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
