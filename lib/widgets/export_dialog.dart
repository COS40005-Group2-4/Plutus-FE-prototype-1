import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import '../l10n/app_localizations.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: 16,
        opacity: 0.15,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.download, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.translate('export_data'),
                      style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildSectionTitle(l10n.translate('export_format')),
              const SizedBox(height: 8),
              _buildFormatSelector(),
              const SizedBox(height: 20),
              _buildSectionTitle(l10n.translate('export_content')),
              const SizedBox(height: 8),
              _buildContentSelector(),
              const SizedBox(height: 20),
              if (_selectedContent != ExportContent.userData) ...[
                _buildSectionTitle(l10n.translate('export_date_range_optional')),
                const SizedBox(height: 8),
                _buildDateRangeSelector(),
                const SizedBox(height: 20),
              ],
              const Divider(),
              const SizedBox(height: 16),
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
                    label: Text(_isExporting ? AppLocalizations.of(context).exporting : AppLocalizations.of(context).export),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textOnLightSecondary,
      ),
    );
  }

  Widget _buildFormatSelector() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
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

  Widget _buildContentSelector() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _buildCheckOption(
          icon: Icons.receipt_long,
          title: l10n.translate('export_transactions'),
          isSelected: _selectedContent == ExportContent.transactions,
          onTap: () => setState(() => _selectedContent = ExportContent.transactions),
        ),
        const SizedBox(height: 8),
        _buildCheckOption(
          icon: Icons.person,
          title: l10n.translate('export_user_data'),
          isSelected: _selectedContent == ExportContent.userData,
          onTap: () => setState(() => _selectedContent = ExportContent.userData),
        ),
        const SizedBox(height: 8),
        _buildCheckOption(
          icon: Icons.select_all,
          title: l10n.translate('export_both'),
          isSelected: _selectedContent == ExportContent.both,
          onTap: () => setState(() => _selectedContent = ExportContent.both),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return GlassContainer(
      borderRadius: 8,
      opacity: 0.1,
      padding: const EdgeInsets.all(12),
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
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 16),
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
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 8),
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
            color: isSelected ? AppColors.primary : AppColors.textOnLightTertiary.withValues(alpha:0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary.withValues(alpha:0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textOnLightSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textOnLightSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckOption({
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
            color: isSelected ? AppColors.primary : AppColors.textOnLightTertiary.withValues(alpha:0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.primary.withValues(alpha:0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textOnLightSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.translate('export_error')}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isExporting = false);
    }
  }
}
