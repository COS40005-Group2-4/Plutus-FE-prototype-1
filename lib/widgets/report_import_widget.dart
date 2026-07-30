import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import 'core/app_card.dart';

// Report Import Button Widget
class ReportImportWidget extends StatelessWidget {
  const ReportImportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return AppCard(
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
                Icon(Icons.upload_file, size: isCompact ? 28 : 40, color: t.text),
                SizedBox(height: isCompact ? 6 : 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).widgetImportReport,
                      style: TextStyle(
                        color: t.text,
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
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
                if (!isCompact) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context).clickImportTransactions,
                    style: TextStyle(color: t.textSecondary, fontSize: 12),
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
