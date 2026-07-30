import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'core/app_card.dart';
import '../l10n/app_localizations.dart';
import '../theme/plutus_tokens.dart';

class CreateDashboardResult {
  final String name;
  final bool useDefaults;
  const CreateDashboardResult({required this.name, required this.useDefaults});
}

class CreateDashboardDialog extends StatefulWidget {
  final List<String> existingNames;

  const CreateDashboardDialog({super.key, required this.existingNames});

  @override
  State<CreateDashboardDialog> createState() => _CreateDashboardDialogState();
}

class _CreateDashboardDialogState extends State<CreateDashboardDialog> {
  final _controller = TextEditingController();
  bool _useDefaults = true;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    final name = _controller.text.trim();
    final l10n = AppLocalizations.of(context);
    if (name.isEmpty) {
      setState(() => _error = l10n.dashboardNameRequired);
      return;
    }
    if (widget.existingNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = l10n.dashboardNameExists);
      return;
    }
    Navigator.of(context).pop(
      CreateDashboardResult(name: name, useDefaults: _useDefaults),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: AppCard(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.createDashboard,
                style: TextStyle(
                  color: t.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                maxLength: 20,
                style: TextStyle(color: t.text),
                decoration: InputDecoration(
                  labelText: l10n.dashboardName,
                  labelStyle: TextStyle(color: t.textSecondary),
                  errorText: _error,
                  counterStyle: TextStyle(color: t.textMuted),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 12),
              RadioListTile<bool>(
                value: true,
                // ignore: deprecated_member_use
                groupValue: _useDefaults,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _useDefaults = v!),
                title: Text(l10n.startWithDefaults,
                    style: TextStyle(color: t.text, fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              RadioListTile<bool>(
                value: false,
                // ignore: deprecated_member_use
                groupValue: _useDefaults,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _useDefaults = v!),
                title: Text(l10n.startEmpty,
                    style: TextStyle(color: t.text, fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _validate,
                    child: Text(l10n.create),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
