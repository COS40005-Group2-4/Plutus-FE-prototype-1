import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ai/category_context.dart';
import '../models/ai/category_suggestion.dart';
import '../models/ai/correction.dart';
import '../models/transaction_model.dart';
import '../services/interfaces/i_ai_category_pipeline.dart';
import '../services/interfaces/i_ai_service.dart';
import '../services/ocr_service.dart';

class AICategoryPipeline implements IAICategoryPipeline {
  final IAIService _aiService;
  final OCRService _ocrService;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  AICategoryPipeline({
    required IAIService aiService,
    required OCRService ocrService,
  })  : _aiService = aiService,
        _ocrService = ocrService;

  @override
  Future<List<CategorySuggestion>> suggest(CategoryContext context) async {
    // 1. Try offline keyword heuristic first (free, instant)
    final keywordResult = _keywordFallback(context);
    if (keywordResult.isNotEmpty && keywordResult.first.displayName != 'Other') {
      return keywordResult;
    }

    // 2. Keyword returned 'Other' — try cloud AI for a better match
    try {
      final Transaction txn = _contextToTransaction(context);
      final CategorySuggestion? suggestion = await _aiService
          .categorizeTransaction(txn, _defaultAccounts, const <Correction>[])
          .timeout(const Duration(seconds: 5));
      if (suggestion != null) {
        return _expandToTopN(suggestion);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AICategoryPipeline: cloud failed: $e');
    }

    // 3. Cloud also failed — return the keyword 'Other' result
    return keywordResult;
  }

  @override
  Stream<List<CategorySuggestion>> suggestStream(CategoryContext context) {
    final StreamController<List<CategorySuggestion>> controller =
        StreamController<List<CategorySuggestion>>();
    Timer(_debounceDuration, () async {
      if (controller.isClosed) return;
      try {
        final List<CategorySuggestion> results = await suggest(context);
        if (!controller.isClosed) controller.add(results);
      } catch (e) {
        if (!controller.isClosed) controller.add(<CategorySuggestion>[]);
      } finally {
        if (!controller.isClosed) controller.close();
      }
    });
    return controller.stream;
  }

  @override
  Future<List<List<CategorySuggestion>>> suggestBatch(
      List<CategoryContext> contexts) async {
    // 1. Run keyword heuristic on all rows first
    final results = List<List<CategorySuggestion>>.generate(
      contexts.length,
      (i) => _keywordFallback(contexts[i]),
    );

    // 2. Collect indices where keyword returned 'Other' (unmatched)
    final unmatchedIndices = <int>[];
    for (int i = 0; i < results.length; i++) {
      if (results[i].first.displayName == 'Other') {
        unmatchedIndices.add(i);
      }
    }

    // 3. Only call cloud AI for unmatched rows
    if (unmatchedIndices.isNotEmpty) {
      try {
        final unmatchedTxns = unmatchedIndices
            .map((i) => _contextToTransaction(contexts[i]))
            .toList();
        final batchResults = await _aiService
            .categorizeBatch(unmatchedTxns, _defaultAccounts, const <Correction>[])
            .timeout(const Duration(seconds: 10));

        for (int j = 0; j < unmatchedIndices.length; j++) {
          final suggestion = j < batchResults.length ? batchResults[j] : null;
          if (suggestion != null) {
            results[unmatchedIndices[j]] = _expandToTopN(suggestion);
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('AICategoryPipeline: batch AI failed: $e');
      }
    }

    return results;
  }

  Transaction _contextToTransaction(CategoryContext context) {
    final double amount = context.amount ?? 0.0;
    final String currency = context.currency ?? 'VND';
    return Transaction(
      date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      payee: context.payee ?? '',
      description: context.description ?? '',
      postings: <Posting>[
        Posting(account: 'Assets:Cash', amount: -amount, commodity: currency),
        Posting(
            account: 'Expenses:Unknown', amount: amount, commodity: currency),
      ],
    );
  }

  List<CategorySuggestion> _expandToTopN(CategorySuggestion primary) {
    final List<CategorySuggestion> results = <CategorySuggestion>[primary];
    if (primary.confidence < 0.9) {
      const List<String> allCategories = <String>[
        'Food',
        'Transportation',
        'Entertainment',
        'Shopping',
        'Bills',
        'Healthcare',
        'Education',
        'Other',
      ];
      for (final String cat in allCategories) {
        final String account = 'Expenses:$cat';
        if (account != primary.account && results.length < 3) {
          results.add(CategorySuggestion(
              account: account,
              confidence: primary.confidence * 0.5));
        }
        if (results.length >= 3) break;
      }
    }
    return results;
  }

  List<CategorySuggestion> _keywordFallback(CategoryContext context) {
    final Map<String, dynamic> data = <String, dynamic>{
      'payee': context.payee ?? '',
      'items': context.items ?? <Map<String, dynamic>>[],
    };
    final String category = _ocrService.suggestCategory(data);
    final bool isExpense =
        !<String>['Salary', 'Freelance', 'Investment', 'Gift']
            .contains(category);
    final String prefix = isExpense ? 'Expenses' : 'Income';
    final double confidence = category == 'Other' ? 0.3 : 0.7;
    return <CategorySuggestion>[
      CategorySuggestion(
          account: '$prefix:$category', confidence: confidence),
    ];
  }

  static const List<String> _defaultAccounts = <String>[
    'Assets:Cash',
    'Expenses:Food',
    'Expenses:Transportation',
    'Expenses:Entertainment',
    'Expenses:Shopping',
    'Expenses:Bills',
    'Expenses:Healthcare',
    'Expenses:Education',
    'Expenses:Other',
    'Income:Salary',
    'Income:Freelance',
    'Income:Investment',
    'Income:Gift',
  ];
}
