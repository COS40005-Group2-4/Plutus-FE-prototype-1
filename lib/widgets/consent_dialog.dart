import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/plutus_tokens.dart';

/// Shows a dialog asking for user consent to data collection.
/// Returns true if user agrees, false if they decline.
Future<bool> showDataConsentDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _DataConsentDialogContent(),
  );
  return result ?? false;
}

class _DataConsentDialogContent extends StatelessWidget {
  const _DataConsentDialogContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;

    return AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        side: BorderSide(color: t.border),
      ),
      title: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            color: t.goldText,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.dataConsentTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dataConsentMessage,
            style: TextStyle(fontSize: 14, color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFeatureItem(
            context,
            Icons.cloud_upload_outlined,
            l10n.dataConsentBackup,
            l10n.dataConsentBackupDesc,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            context,
            Icons.sync_outlined,
            l10n.dataConsentSync,
            l10n.dataConsentSyncDesc,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.warning.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.warning.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: t.warning.text,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.dataConsentDecline,
                    style: TextStyle(fontSize: 12, color: t.warning.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: t.textSecondary),
          child: Text(l10n.dataConsentDeclineBtn),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.dataConsentAgreeBtn),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: t.brandNavy,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows a general Terms of Use dialog for local/guest users.
/// Returns true if user agrees, false if they decline.
Future<bool> showTermsDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _TermsDialogContent(),
  );
  return result ?? false;
}

class _TermsDialogContent extends StatelessWidget {
  const _TermsDialogContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;

    return AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        side: BorderSide(color: t.border),
      ),
      title: Row(
        children: [
          Icon(
            Icons.gavel_outlined,
            color: t.goldText,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.tcTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        l10n.tcMessage,
        style: TextStyle(fontSize: 14, color: t.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: t.textSecondary),
          child: Text(l10n.tcDeclineBtn),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.tcAgreeBtn),
        ),
      ],
    );
  }
}
