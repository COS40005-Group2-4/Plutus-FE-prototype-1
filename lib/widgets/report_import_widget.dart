import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

// Report Import Button Widget
class ReportImportWidget extends StatelessWidget {
  const ReportImportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: AppColors.warning,
      opacity: 0.2,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 160;
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file, size: isCompact ? 28 : 40, color: Colors.white),
                SizedBox(height: isCompact ? 6 : 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).widgetImportReport,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 13 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Tooltip(
                      message: AppLocalizations.of(context).widgetHelpImport,
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: AppColors.textTertiary(Theme.of(context).brightness),
                      ),
                    ),
                  ],
                ),
                if (!isCompact) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context).clickImportTransactions,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: isCompact ? 8 : 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, "/import");
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context).import),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }
}
