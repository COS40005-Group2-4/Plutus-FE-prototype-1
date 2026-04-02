import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import '../l10n/app_localizations.dart';

const Color red = Color(0xFFEA4335);

// Report Export Button Widget
class ReportExportWidget extends StatefulWidget {
  const ReportExportWidget({super.key});

  @override
  State<ReportExportWidget> createState() => _ReportExportWidgetState();
}

class _ReportExportWidgetState extends State<ReportExportWidget> {
  Future<void> _showExportDialog() async {
    Navigator.pushNamed(context, '/report-config');
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: red,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 160;
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: isCompact ? 28 : 40, color: Colors.white),
                SizedBox(height: isCompact ? 6 : 12),
                Text(
                  AppLocalizations.of(context).widgetExportReport,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 13 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).clickExportTransactions,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: isCompact ? 8 : 16),
                ElevatedButton.icon(
                  onPressed: _showExportDialog,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: Text(AppLocalizations.of(context).export),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
