import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transaction_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/export_dialog.dart';
import '../widgets/export_preview_dialog.dart';
import '../providers/auth_provider.dart';
import '../services/export_service.dart';
import '../services/user_service.dart';
import '../l10n/app_localizations.dart';

const Color red = Color(0xFFEA4335);

// Report Export Button Widget
class ReportExportWidget extends StatefulWidget {
  const ReportExportWidget({super.key});

  @override
  State<ReportExportWidget> createState() => _ReportExportWidgetState();
}

class _ReportExportWidgetState extends State<ReportExportWidget> {
  final TransactionService _transactionService = TransactionService();
  final ExportService _exportService = ExportService();
  final UserService _userService = UserService();
  bool _isExporting = false;

  Future<void> _showExportDialog() async {
    final options = await showDialog<ExportOptions>(
      context: context,
      builder: (context) => const ExportDialog(),
    );

    if (options == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text('Generating export...', overflow: TextOverflow.ellipsis)),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUserId != null
          ? await _userService.getUserById(authProvider.currentUserId!)
          : null;

      // Get transactions
      final transactions = await _transactionService.getTransactions();

      // Generate export
      final result = await _exportService.exportData(
        options: options,
        transactions: transactions,
        user: user,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show preview dialog
      await showDialog(
        context: context,
        builder: (context) => ExportPreviewDialog(
          filePath: result.filePath,
          format: result.format,
          pdfDocument: result.pdfDocument,
          txtContent: result.txtContent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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
                  onPressed: _isExporting ? null : _showExportDialog,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(red),
                          ),
                        )
                      : const Icon(Icons.save_alt, size: 18),
                  label: Text(_isExporting ? AppLocalizations.of(context).exporting : AppLocalizations.of(context).export),
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
