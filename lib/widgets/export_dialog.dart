import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/export_service.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import 'core/app_card.dart';

final _dateRangeFormatter = DateFormat('MMM dd, yyyy');

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  ExportContent _selectedContent = ExportContent.both;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.download, size: 28, color: t.text),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.translate('export_data'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: t.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: t.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: t.border),
              const SizedBox(height: AppSpacing.lg),
              _buildSectionTitle(l10n.translate('export_format'), t),
              const SizedBox(height: AppSpacing.sm),
              _buildFormatSelector(t),
              const SizedBox(height: 20),
              _buildSectionTitle(l10n.translate('export_content'), t),
              const SizedBox(height: AppSpacing.sm),
              _buildContentSelector(t),
              const SizedBox(height: 20),
              if (_selectedContent != ExportContent.userData) ...[
                _buildSectionTitle(l10n.translate('export_date_range_optional'), t),
                const SizedBox(height: AppSpacing.sm),
                _buildDateRangeSelector(t),
                const SizedBox(height: 20),
              ],
              Divider(color: t.border),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.translate('export_cancel')),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download),
                    label: Text(_isExporting ? l10n.exporting : l10n.export),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, PlutusTokens t) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: t.textSecondary,
      ),
    );
  }

  Widget _buildFormatSelector(PlutusTokens t) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            t: t,
            icon: Icons.picture_as_pdf,
            title: l10n.translate('export_pdf'),
            description: l10n.translate('export_pdf_desc'),
            isSelected: _selectedFormat == ExportFormat.pdf,
            onTap: () => setState(() => _selectedFormat = ExportFormat.pdf),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            t: t,
            icon: Icons.text_snippet,
            title: l10n.translate('export_txt'),
            description: l10n.translate('export_txt_desc'),
            isSelected: _selectedFormat == ExportFormat.txt,
            onTap: () => setState(() => _selectedFormat = ExportFormat.txt),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSelector(PlutusTokens t) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildCheckOption(
          t: t,
          icon: Icons.receipt_long,
          title: l10n.translate('export_transactions'),
          isSelected: _selectedContent == ExportContent.transactions,
          onTap: () => setState(() => _selectedContent = ExportContent.transactions),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCheckOption(
          t: t,
          icon: Icons.person,
          title: l10n.translate('export_user_data'),
          isSelected: _selectedContent == ExportContent.userData,
          onTap: () => setState(() => _selectedContent = ExportContent.userData),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCheckOption(
          t: t,
          icon: Icons.select_all,
          title: l10n.translate('export_both'),
          isSelected: _selectedContent == ExportContent.both,
          onTap: () => setState(() => _selectedContent = ExportContent.both),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector(PlutusTokens t) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = _dateRangeFormatter;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectStartDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.translate('export_start_date'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _startDate != null ? dateFormat.format(_startDate!) : l10n.translate('export_all'),
                            style: TextStyle(fontSize: 14, color: t.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 16, color: t.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectEndDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.translate('export_end_date'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _endDate != null ? dateFormat.format(_endDate!) : l10n.translate('export_all'),
                            style: TextStyle(fontSize: 14, color: t.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 16, color: t.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => setState(() {
                _startDate = null;
                _endDate = null;
              }),
              icon: const Icon(Icons.clear, size: 16),
              label: Text(l10n.translate('export_clear_range')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required PlutusTokens t,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? t.gold : t.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? t.goldSelectedFill : t.surfaceSubtle,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? t.goldText : t.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? t.goldText : t.text,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: t.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckOption({
    required PlutusTokens t,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? t.gold : t.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? t.goldSelectedFill : t.surfaceSubtle,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? t.goldText : t.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? t.goldText : t.text,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: t.gold,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _handleExport() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isExporting = true);

    try {
      final options = ExportOptions(
        format: _selectedFormat,
        content: _selectedContent,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;
      Navigator.of(context).pop(options);
    } catch (e) {
      if (!mounted) return;
      final PlutusTokens t = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate('export_error')}: $e'),
          backgroundColor: t.error.text,
        ),
      );
      setState(() => _isExporting = false);
    }
  }
}
