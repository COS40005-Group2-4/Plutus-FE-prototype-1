import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../models/backup_models.dart';
import '../theme/app_radius.dart';
import '../theme/plutus_tokens.dart';

/// Shows a glassmorphic conflict dialog with three radio options.
/// Pre-selects "Keep local and upload" as default.
/// Returns the user's [ConflictChoice], or null if dismissed.
Future<ConflictChoice?> showConflictDialog(BuildContext context) {
  return showDialog<ConflictChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _ConflictDialogContent(),
  );
}

class _ConflictDialogContent extends StatefulWidget {
  const _ConflictDialogContent();

  @override
  State<_ConflictDialogContent> createState() => _ConflictDialogContentState();
}

class _ConflictDialogContentState extends State<_ConflictDialogContent> {
  ConflictChoice _selected = ConflictChoice.keepLocal;

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
          Icon(Icons.warning_amber_rounded, color: t.warning.text),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l10n.backupConflictTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.backupConflictMessage),
          const SizedBox(height: AppSpacing.lg),
          RadioListTile<ConflictChoice>(
            value: ConflictChoice.overrideLocal,
            // ignore: deprecated_member_use
            groupValue: _selected,
            // ignore: deprecated_member_use
            onChanged: (v) => setState(() => _selected = v!),
            title: Text(l10n.backupConflictOverride),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ConflictChoice>(
            value: ConflictChoice.keepLocal,
            // ignore: deprecated_member_use
            groupValue: _selected,
            // ignore: deprecated_member_use
            onChanged: (v) => setState(() => _selected = v!),
            title: Text(l10n.backupConflictKeepLocal),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ConflictChoice>(
            value: ConflictChoice.cancel,
            // ignore: deprecated_member_use
            groupValue: _selected,
            // ignore: deprecated_member_use
            onChanged: (v) => setState(() => _selected = v!),
            title: Text(l10n.backupConflictCancel),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
