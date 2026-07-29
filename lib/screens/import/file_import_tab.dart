import 'dart:io';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../models/ai/category_context.dart';
import '../../models/ai/category_suggestion.dart';
import '../../services/interfaces/i_ai_category_pipeline.dart';
import '../../services/interfaces/i_transaction_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/import/file_preview_table.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/insights_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class FileImportTab extends ConsumerStatefulWidget {
  const FileImportTab({super.key});

  @override
  ConsumerState<FileImportTab> createState() => _FileImportTabState();
}

class _FileImportTabState extends ConsumerState<FileImportTab> {
  late ITransactionService _service;
  late IAICategoryPipeline _aiPipeline;

  String? _fileName;
  bool _loading = false;
  bool _importing = false;

  // Preview state
  List<Map<String, dynamic>>? _parsedTransactions;
  Set<int> _selectedIndices = {};
  Map<int, List<CategorySuggestion>> _aiSuggestions = {};
  bool _isAiCategorizing = false;
  int _aiProgress = 0;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance<ITransactionService>();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _service.setCurrentUser(currentUserId);
    }
    _aiPipeline = GetIt.instance<IAICategoryPipeline>();
  }

  Future<void> _pickFile() async {
    // file_picker 11 removed the `platform` instance getter; FilePicker is now
    // an abstract final class exposing these as statics.
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv', 'xml', 'ledger', 'txt'],
    );

    if (result != null) {
      final file = result.files.single;
      setState(() {
        _fileName = file.name;
        _parsedTransactions = null;
        _aiSuggestions = {};
      });
      if (file.path != null) {
        _parseFile(file.path!);
      }
    }
  }

  Future<void> _parseFile(String filePath) async {
    setState(() => _loading = true);
    try {
      final content = await File(filePath).readAsString();
      final ext = filePath.split('.').last.toLowerCase();

      List<Map<String, dynamic>> transactions;
      switch (ext) {
        case 'csv':
          transactions = await _service.parseCsvFile(content);
          break;
        case 'json':
          final result = await _service.parseJsonFile(content);
          // parseJsonFile returns a map with a 'transactions' key or a single transaction
          if (result.containsKey('transactions') && result['transactions'] is List) {
            transactions = List<Map<String, dynamic>>.from(
              (result['transactions'] as List).map((t) => Map<String, dynamic>.from(t as Map)),
            );
          } else {
            transactions = [result];
          }
          break;
        case 'xml':
          transactions = await _service.parseXmlFile(content);
          break;
        case 'ledger':
        case 'txt':
          transactions = await _service.parseLedgerFile(content);
          break;
        default:
          throw Exception('Unsupported file format: $ext');
      }

      setState(() {
        _parsedTransactions = transactions;
        _selectedIndices = Set.from(List.generate(transactions.length, (i) => i));
        _loading = false;
      });

      // Run batch AI categorization
      _runBatchCategorization(transactions);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parse error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _runBatchCategorization(List<Map<String, dynamic>> transactions) async {
    setState(() {
      _isAiCategorizing = true;
      _aiProgress = 0;
    });

    try {
      final contexts = transactions.map((txn) => CategoryContext(
        payee: txn['payee']?.toString(),
        description: txn['description']?.toString(),
        amount: (txn['amount'] is num) ? (txn['amount'] as num).toDouble() : double.tryParse(txn['amount']?.toString() ?? ''),
        currency: txn['currency']?.toString(),
      )).toList();

      final results = await _aiPipeline.suggestBatch(contexts);

      final suggestions = <int, List<CategorySuggestion>>{};
      for (int i = 0; i < results.length; i++) {
        suggestions[i] = results[i];
      }

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _isAiCategorizing = false;
          _aiProgress = results.length;
          // Auto-fill categories from suggestions
          for (int i = 0; i < transactions.length; i++) {
            if (suggestions[i] != null && suggestions[i]!.isNotEmpty) {
              transactions[i]['category'] = suggestions[i]!.first.displayName;
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Batch categorization error: $e');
      if (mounted) setState(() => _isAiCategorizing = false);
    }
  }

  Future<void> _importSelected() async {
    if (_parsedTransactions == null) return;
    setState(() => _importing = true);

    int imported = 0;
    int skipped = 0;

    try {
      for (final index in _selectedIndices.toList()..sort()) {
        final txn = _parsedTransactions![index];
        try {
          await _service.importTransaction(txn);
          imported++;
        } catch (e) {
          skipped++;
          if (kDebugMode) debugPrint('Skip row $index: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $imported transactions. $skipped skipped.'),
            backgroundColor: AppColors.success,
          ),
        );
        if (context.mounted) {
          ref.read(insightsNotifierProvider.notifier).onTransactionsImported();
        }
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Use Expanded properly: if preview table is showing, we need the parent to provide bounded height.
    // Wrap in a Column with Expanded for the preview table.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderRadius: AppRadius.lg,
        opacity: 0.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Import from File',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.selectFile),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('File: $_fileName', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            // Preview table
            if (_parsedTransactions != null && !_loading) ...[
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: FilePreviewTable(
                  transactions: _parsedTransactions!,
                  aiSuggestions: _aiSuggestions,
                  selectedIndices: _selectedIndices,
                  onSelectionChanged: (newSet) => setState(() => _selectedIndices = newSet),
                  onTransactionEdited: (index, updated) {
                    setState(() => _parsedTransactions![index] = updated);
                  },
                  onCategoryChanged: (index, category) {
                    setState(() => _parsedTransactions![index]['category'] = category);
                  },
                  isAiLoading: _isAiCategorizing,
                  aiProgress: _aiProgress,
                  aiTotal: _parsedTransactions!.length,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _importing || _selectedIndices.isEmpty ? null : _importSelected,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.success,
                ),
                child: _importing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Import Selected (${_selectedIndices.length})',
                        style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
