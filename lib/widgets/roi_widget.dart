import 'package:flutter/material.dart';
import 'glass_container.dart';
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
        print('Could not load currency from settings, using default: $e');
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
      print('Error loading ROI: $e');
      if (mounted) {
        setState(() {
          _roiValue = '0.00';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GlassContainer(
      color: const Color(0xFF4A90E2),
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).roi,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).returnOnInvestment,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              opacity: 0.1,
              borderRadius: 8,
              child: Column(
                children: [
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '$_roiValue%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).currentRoi,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadRoiData,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }
}
