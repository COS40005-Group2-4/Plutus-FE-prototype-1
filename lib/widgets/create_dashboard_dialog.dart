import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textOnLight;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textOnLightSecondary;
    final tertiaryTextColor = isDark ? Colors.white54 : AppColors.textOnLightTertiary;
    final containerColor = isDark ? AppColors.menuBackground : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.15);

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: GlassContainer(
        color: containerColor,
        opacity: isDark ? 0.85 : 0.9,
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
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLength: 20,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: l10n.dashboardName,
                  labelStyle: TextStyle(color: secondaryTextColor),
                  errorText: _error,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.error),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.error),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterStyle: TextStyle(color: tertiaryTextColor),
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
                    style: TextStyle(color: textColor, fontSize: 14)),
                activeColor: AppColors.primary,
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
                    style: TextStyle(color: textColor, fontSize: 14)),
                activeColor: AppColors.primary,
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
                        style: TextStyle(color: secondaryTextColor)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _validate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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
