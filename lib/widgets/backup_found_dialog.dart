import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/plutus_tokens.dart';

/// Shows a dialog when a cloud backup is found on a new device.
/// Returns true if user wants to restore, false if they want to start fresh.
Future<bool?> showBackupFoundDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
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
            Icon(Icons.cloud_download, color: t.goldText),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.backupFoundTitle)),
          ],
        ),
        content: Text(l10n.backupFoundMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.backupFoundSkip),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupFoundRestore),
          ),
        ],
      );
    },
  );
}
