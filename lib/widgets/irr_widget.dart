import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'glass_container.dart';
import '../theme/app_colors.dart';
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
  String _irrValue = '0.00';
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadIrrData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIrrData();
  }

  Future<void> _loadIrrData() async {
    setState(() => _isLoading = true);

    try {
      String currency = 'VND';
      try {
        final settingsService = SettingsService();
        currency = await settingsService.getDefaultCurrency(1);
      } catch (e) {
        debugPrint('Could not load currency from settings, using default: $e');
      }

      final investmentService = sl<IInvestmentService>();
      final data = await investmentService.getInvestmentReport(currency: currency);

      if (mounted) {
        final irr = (data['irr'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          _irrValue = irr.toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading IRR: $e');
      if (mounted) {
        setState(() {
          _irrValue = '0.00';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGauge(double value, bool isCompact) {
    final clampedValue = value.clamp(-100.0, 100.0);
    final normalizedValue = (clampedValue + 100) / 200;
    final gaugeColor = clampedValue >= 0 ? AppColors.accent : Colors.red;

    return SizedBox(
      height: isCompact ? 70 : 90,
      width: isCompact ? 70 : 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 180,
              sectionsSpace: 0,
              centerSpaceRadius: isCompact ? 22 : 28,
              sections: [
                PieChartSectionData(
                  color: gaugeColor.withValues(alpha: 0.8),
                  value: normalizedValue * 180,
                  title: '',
                  radius: isCompact ? 10 : 14,
                ),
                PieChartSectionData(
                  color: Colors.white.withValues(alpha: 0.1),
                  value: (1 - normalizedValue) * 180,
                  title: '',
                  radius: isCompact ? 10 : 14,
                ),
                PieChartSectionData(
                  color: Colors.transparent,
                  value: 180,
                  title: '',
                  radius: isCompact ? 10 : 14,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$_irrValue%',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 13 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GlassContainer(
      color: AppColors.accent,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 180;
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).irr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isCompact)
                  Text(
                    AppLocalizations.of(context).internalRateOfReturn,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: isCompact ? 4 : 8),
                _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : _buildGauge(double.tryParse(_irrValue) ?? 0, isCompact),
                if (!isCompact)
                  Text(
                    AppLocalizations.of(context).currentIrr,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                  onPressed: _loadIrrData,
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
