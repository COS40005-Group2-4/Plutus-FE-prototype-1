import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Shows a dialog when a cloud backup is found on a new device.
/// Returns true if user wants to restore, false if they want to start fresh.
Future<bool?> showBackupFoundDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1A3A4A).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? const Color(0xFF2A5470).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.cloud_download,
                color: isDark ? const Color(0xFF5DADE2) : Colors.blue),
            const SizedBox(width: 8),
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
