import 'dart:io';
import '../../theme/app_spacing.dart';
import '../../theme/plutus_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ai/category_context.dart';
import '../../models/ai/category_suggestion.dart';
import '../../services/interfaces/i_ai_category_pipeline.dart';
import '../../services/interfaces/i_transaction_service.dart';
import '../../services/ocr_service.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/insights_notifier.dart';
import '../../providers/settings_notifier.dart';
import '../../widgets/core/app_card.dart';
import '../../widgets/import/ai_category_field.dart';
import '../../widgets/import/import_feedback.dart';
import '../../widgets/import/zoomable_image_viewer.dart';
import '../../l10n/app_localizations.dart';

class ScanImportTab extends ConsumerStatefulWidget {
  const ScanImportTab({super.key});

  @override
  ConsumerState<ScanImportTab> createState() => _ScanImportTabState();
}

class _ScanImportTabState extends ConsumerState<ScanImportTab> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();
  late ITransactionService _service;
  late IAICategoryPipeline _aiPipeline;

  XFile? _imageFile;
  Map<String, dynamic>? _scannedData;
  bool _scanning = false;
  bool _saving = false;

  // Editable extracted fields
  late TextEditingController _payeeController;
  late TextEditingController _amountController;
  late TextEditingController _descController;
  String _currency = 'VND';
  DateTime _selectedDate = DateTime.now();
  final String _type = 'expense';

  // AI category state
  List<CategorySuggestion> _aiSuggestions = [];
  bool _isAiLoading = false;
  bool _isAiSuggested = false;
  String? _selectedCategory;

  static const List<String> _expenseCategories = [
    'Food', 'Transportation', 'Entertainment', 'Shopping',
    'Bills', 'Healthcare', 'Education', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _payeeController = TextEditingController();
    _amountController = TextEditingController();
    _descController = TextEditingController();

    _service = GetIt.instance<ITransactionService>();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _service.setCurrentUser(currentUserId);
    }
    _aiPipeline = GetIt.instance<IAICategoryPipeline>();
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = image;
          _scannedData = null;
          _aiSuggestions = [];
          _isAiSuggested = false;
        });
        _processImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).errorPickingImage}$e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;
    setState(() => _scanning = true);

    try {
      // Read OCR mode from settings
      final settingsState = ref.read(settingsNotifierProvider);
      final ocrMode = settingsState.ocrMode;

      final details = await _ocrService.processInvoice(_imageFile!.path, mode: ocrMode);

      if (details != null && !details.containsKey('error')) {
        setState(() {
          _scannedData = details;
          _payeeController.text = details['payee']?.toString() ?? '';
          _amountController.text = details['amount']?.toString() ?? '';
          if (details['date'] != null) {
            try {
              _selectedDate = DateTime.parse(details['date']);
            } catch (_) {}
          }
          if (details['currency'] != null) {
            final c = details['currency'].toString().toUpperCase();
            if (['VND', 'USD', 'EUR'].contains(c)) _currency = c;
          }
        });

        // Run AI categorization in parallel
        _categorizeScannedData(details);
      } else if (mounted) {
        final error = details?['error'] ?? AppLocalizations.of(context).couldNotReadImage;
        showResultSnackBar(context, error, isError: true);
      }
    } catch (e) {
      if (mounted) {
        showResultSnackBar(context, '${AppLocalizations.of(context).ocrErrorPrefix}$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _categorizeScannedData(Map<String, dynamic> data) async {
    setState(() => _isAiLoading = true);
    try {
      final context = CategoryContext(
        payee: data['payee']?.toString(),
        amount: (data['amount'] as num?)?.toDouble(),
        currency: data['currency']?.toString(),
        items: (data['items'] as List?)?.cast<Map<String, dynamic>>(),
      );
      final suggestions = await _aiPipeline.suggest(context);
      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _isAiLoading = false;
          if (suggestions.isNotEmpty) {
            _isAiSuggested = true;
            _selectedCategory = suggestions.first.displayName;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) return;
    setState(() => _saving = true);

    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final categoryPath = _selectedCategory ?? 'Other';
      const assetAccount = 'Assets:Cash';
      final categoryAccount = _type == 'expense'
          ? 'Expenses:$categoryPath'
          : 'Income:$categoryPath';

      final postings = _type == 'expense'
          ? [
              {'account': assetAccount, 'amount': -amount.abs(), 'commodity': _currency},
              {'account': categoryAccount, 'amount': amount.abs(), 'commodity': _currency},
            ]
          : [
              {'account': assetAccount, 'amount': amount.abs(), 'commodity': _currency},
              {'account': categoryAccount, 'amount': -amount.abs(), 'commodity': _currency},
            ];

      final transaction = {
        'date': _selectedDate.toIso8601String(),
        'payee': _payeeController.text,
        'description': _descController.text,
        'postings': postings,
        'amount': _type == 'expense' ? -amount.abs() : amount.abs(),
        'currency': _currency,
        'type': _type,
        'category': categoryAccount,
        'account': assetAccount,
      };

      await _service.importTransaction(transaction);

      if (mounted) {
        showResultSnackBar(context, AppLocalizations.of(context).transactionSavedSuccessfully, isError: false);
        if (context.mounted) {
          ref.read(insightsNotifierProvider.notifier).onTransactionsImported();
        }
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (mounted) {
        showResultSnackBar(context, '${AppLocalizations.of(context).errorSaving}$e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Pick image buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _scanning ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: Text(l10n.selectInvoiceImage),
                ),
                ElevatedButton.icon(
                  onPressed: _scanning ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.camera),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_imageFile != null) ...[
              // Adaptive layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 600) {
                    return _buildSideBySideLayout();
                  }
                  return _buildStackedLayout();
                },
              ),
            ],

            if (_scanning)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySideLayout() {
    return SizedBox(
      height: 500,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ZoomableImageViewer(
              imageProvider: kIsWeb
                  ? NetworkImage(_imageFile!.path)
                  : FileImage(File(_imageFile!.path)) as ImageProvider,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: SingleChildScrollView(child: _buildExtractedFields())),
        ],
      ),
    );
  }

  Widget _buildStackedLayout() {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: ZoomableImageViewer(
            imageProvider: kIsWeb
                ? NetworkImage(_imageFile!.path)
                : FileImage(File(_imageFile!.path)) as ImageProvider,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildExtractedFields(),
      ],
    );
  }

  Widget _buildExtractedFields() {
    final l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    if (_scannedData == null && !_scanning) {
      return Center(child: Text(l10n.processingImage));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.extractedFields, style: TextStyle(fontSize: 12, color: t.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _payeeController,
          decoration: InputDecoration(labelText: l10n.payee, border: const OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: l10n.amount, border: const OutlineInputBorder(), isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: [
                  DropdownMenuItem(value: 'VND', child: Text(l10n.vnd)),
                  DropdownMenuItem(value: 'USD', child: Text(l10n.usd)),
                  DropdownMenuItem(value: 'EUR', child: Text(l10n.eur)),
                ],
                onChanged: (val) => setState(() => _currency = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.date,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            child: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
          ),
        ),
        const SizedBox(height: 12),
        AiCategoryField(
          categories: _expenseCategories,
          selectedCategory: _selectedCategory,
          isExpense: _type == 'expense',
          onCategoryChanged: (val) {
            setState(() {
              _selectedCategory = val;
              _isAiSuggested = false;
            });
          },
          aiSuggestions: _aiSuggestions,
          isAiLoading: _isAiLoading,
          isAiSuggested: _isAiSuggested,
        ),
        const SizedBox(height: 12),
        if (_scannedData != null && _scannedData!['items'] != null) ...[
          Text(l10n.items, style: TextStyle(fontSize: 12, color: t.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          ...(_scannedData!['items'] as List).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item['description'] ?? '', style: const TextStyle(fontSize: 13))),
                    Text('${item['amount']}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: _descController,
          decoration: InputDecoration(labelText: l10n.note, border: const OutlineInputBorder(), isDense: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: _saving || _scanning ? null : _saveTransaction,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.confirmAndSave, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
