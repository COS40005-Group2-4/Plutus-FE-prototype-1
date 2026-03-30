import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'glass_container.dart';
import '../theme/app_colors.dart';
import '../services/backend_ffi_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';

class RoiWidget extends StatefulWidget {
  const RoiWidget({super.key});

  @override
  State<RoiWidget> createState() => _RoiWidgetState();
}

class _RoiWidgetState extends State<RoiWidget> with AutomaticKeepAliveClientMixin {
  final BackendFfiService _ffiService = BackendFfiService();
  String _roiValue = '0.00';
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRoiData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRoiData();
  }

  Future<void> _loadRoiData() async {
    setState(() => _isLoading = true);
    
    try {
      String currency = 'VND'; // Default
      
      try {
        final settingsService = SettingsService();
        currency = await settingsService.getDefaultCurrency(1);
      } catch (e) {
        debugPrint('Could not load currency from settings, using default: $e');
      }
      
      final data = await _ffiService.getRoiData(currency: currency);
      if (mounted) {
        String roiStr = data['roi'] ?? '0.00';
        
        roiStr = roiStr.replaceAll('%', '');
        double roi = double.tryParse(roiStr) ?? 0.0;
        
        setState(() {
          _roiValue = roi.toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ROI: $e');
      if (mounted) {
        setState(() {
          _roiValue = '0.00';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGauge(double value, bool isCompact) {
    final clampedValue = value.clamp(-100.0, 100.0);
    final normalizedValue = (clampedValue + 100) / 200; // 0 to 1
    final brightness = Theme.of(context).brightness;
    final gaugeColor = clampedValue >= 0 ? AppColors.positive(brightness) : AppColors.negative(brightness);

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
                  color: gaugeColor.withValues(alpha:0.8),
                  value: normalizedValue * 180,
                  title: '',
                  radius: isCompact ? 10 : 14,
                ),
                PieChartSectionData(
                  color: Colors.white.withValues(alpha:0.1),
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
              '$_roiValue%',
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
      color: AppColors.primaryDark,
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
                  AppLocalizations.of(context).roi,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isCompact)
                  Text(
                    AppLocalizations.of(context).returnOnInvestment,
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
                    : _buildGauge(double.tryParse(_roiValue) ?? 0, isCompact),
                if (!isCompact)
                  Text(
                    AppLocalizations.of(context).currentRoi,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                  onPressed: _loadRoiData,
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
