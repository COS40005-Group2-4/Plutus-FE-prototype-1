import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../l10n/app_localizations.dart';

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
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: GlassContainer(
        color: const Color(0xFF2C3E50),
        opacity: 0.85,
        borderRadius: 16,
        blur: 15,
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.createDashboard,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLength: 20,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.dashboardName,
                  labelStyle: const TextStyle(color: Colors.white70),
                  errorText: _error,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF4285F4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterStyle: const TextStyle(color: Colors.white54),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 12),
              RadioListTile<bool>(
                value: true,
                groupValue: _useDefaults,
                onChanged: (v) => setState(() => _useDefaults = v!),
                title: Text(l10n.startWithDefaults,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                activeColor: const Color(0xFF4285F4),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              RadioListTile<bool>(
                value: false,
                groupValue: _useDefaults,
                onChanged: (v) => setState(() => _useDefaults = v!),
                title: Text(l10n.startEmpty,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                activeColor: const Color(0xFF4285F4),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _validate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                    ),
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
