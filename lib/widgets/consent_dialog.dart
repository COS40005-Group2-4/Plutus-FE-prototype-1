import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.3)
              : AppColors.textOnLightTertiary.withValues(alpha: 0.3),
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            color: isDark ? AppColors.accent : AppColors.primary,
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
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textOnLightSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            context,
            Icons.cloud_upload_outlined,
            l10n.dataConsentBackup,
            l10n.dataConsentBackupDesc,
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            context,
            Icons.sync_outlined,
            l10n.dataConsentSync,
            l10n.dataConsentSyncDesc,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.dataConsentDecline,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.warning.withValues(alpha: 0.7) : AppColors.warning,
                    ),
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
          child: Text(
            l10n.dataConsentDeclineBtn,
            style: TextStyle(color: AppColors.error),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.textOnDark,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.accent : AppColors.primary,
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
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textOnDarkTertiary : AppColors.textOnLightSecondary,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.3)
              : AppColors.textOnLightTertiary.withValues(alpha: 0.3),
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.gavel_outlined,
            color: isDark ? AppColors.accent : AppColors.primary,
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
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textOnDarkSecondary : AppColors.textOnLightSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.tcDeclineBtn,
            style: TextStyle(color: AppColors.textOnLightSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.textOnDark,
          ),
          child: Text(l10n.tcAgreeBtn),
        ),
      ],
    );
  }
}
