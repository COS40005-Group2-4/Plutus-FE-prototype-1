import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../services/backend_ffi_service.dart';
import '../l10n/app_localizations.dart';

class IrrWidget extends StatefulWidget {
  const IrrWidget({super.key});

  @override
  State<IrrWidget> createState() => _IrrWidgetState();
}

class _IrrWidgetState extends State<IrrWidget> {
  final BackendFfiService _ffiService = BackendFfiService();
  String _irrValue = '0.00';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIrrData();
  }

  Future<void> _loadIrrData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _ffiService.getRoiData();
      if (mounted) {
        String irrStr = data['irr'] ?? '0.00';
        
        // Remove any existing % signs
        irrStr = irrStr.replaceAll('%', '');
        
        // Parse as double and format
        double irr = double.tryParse(irrStr) ?? 0.0;
        
        setState(() {
          _irrValue = irr.toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading IRR: $e');
      if (mounted) {
        setState(() {
          _irrValue = '0.00';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: const Color(0xFF5DADE2),
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).irr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).internalRateOfReturn,
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
                          '$_irrValue%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).currentIrr,
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
              onPressed: _loadIrrData,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }
}
