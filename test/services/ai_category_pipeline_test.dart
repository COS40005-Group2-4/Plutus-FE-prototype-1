import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/ai/category_suggestion.dart';
import 'package:plutus_fe_prototype/models/ai/category_context.dart';
import 'package:plutus_fe_prototype/services/ai_category_pipeline.dart';
import 'package:plutus_fe_prototype/services/ocr_service.dart';
import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late AICategoryPipeline pipeline;
  late MockIAIService mockAIService;
  late OCRService ocrService;

  setUp(() {
    mockAIService = MockIAIService();
    ocrService = OCRService();
    pipeline = AICategoryPipeline(aiService: mockAIService, ocrService: ocrService);
  });

  group('suggest', () {
    test('returns keyword result directly when keyword matches (no cloud call)', () async {
      // 'Starbucks' matches 'Food' in keywords — cloud AI should NOT be called
      final ctx = createTestCategoryContext(payee: 'Starbucks');
      final results = await pipeline.suggest(ctx);

      expect(results, isNotEmpty);
      expect(results.first.displayName, 'Food');
      expect(results.first.confidence, 0.7);
      // Verify cloud AI was never called
      verifyNever(mockAIService.categorizeTransaction(any, any, any));
    });

    test('returns keyword result for known Vietnamese brand (no cloud call)', () async {
      final ctx = createTestCategoryContext(payee: 'Highlands Coffee');
      final results = await pipeline.suggest(ctx);

      expect(results.first.displayName, 'Food');
      verifyNever(mockAIService.categorizeTransaction(any, any, any));
    });

    test('calls cloud AI when keyword returns Other', () async {
      when(mockAIService.categorizeTransaction(any, any, any))
          .thenAnswer((_) async => const CategorySuggestion(account: 'Expenses:Entertainment', confidence: 0.88));

      // 'xyzabc123' won't match any keyword — should fall through to cloud
      final ctx = createTestCategoryContext(payee: 'xyzabc123');
      final results = await pipeline.suggest(ctx);

      expect(results.first.displayName, 'Entertainment');
      expect(results.first.confidence, 0.88);
      verify(mockAIService.categorizeTransaction(any, any, any)).called(1);
    });

    test('returns Other when both keyword and cloud fail', () async {
      when(mockAIService.categorizeTransaction(any, any, any)).thenAnswer((_) async => null);

      final ctx = createTestCategoryContext(payee: 'xyzabc123');
      final results = await pipeline.suggest(ctx);

      expect(results.first.displayName, 'Other');
      expect(results.first.confidence, 0.3);
    });

    test('returns Other when keyword misses and cloud throws', () async {
      when(mockAIService.categorizeTransaction(any, any, any)).thenThrow(Exception('Network error'));

      final ctx = createTestCategoryContext(payee: 'xyzabc123');
      final results = await pipeline.suggest(ctx);

      expect(results.first.displayName, 'Other');
    });
  });

  group('suggestBatch', () {
    test('only sends unmatched rows to cloud AI', () async {
      when(mockAIService.categorizeBatch(any, any, any)).thenAnswer((_) async => [
        const CategorySuggestion(account: 'Expenses:Entertainment', confidence: 0.85),
      ]);

      final contexts = [
        createTestCategoryContext(payee: 'Starbucks'),       // keyword: Food ✓
        createTestCategoryContext(payee: 'Grab'),             // keyword: Transportation ✓
        createTestCategoryContext(payee: 'some_unknown_xyz'), // keyword: Other → cloud
      ];
      final results = await pipeline.suggestBatch(contexts);

      expect(results.length, 3);
      expect(results[0].first.displayName, 'Food');           // from keyword
      expect(results[1].first.displayName, 'Transportation'); // from keyword
      expect(results[2].first.displayName, 'Entertainment');  // from cloud

      // Cloud should only receive 1 transaction (the unmatched one)
      final captured = verify(mockAIService.categorizeBatch(captureAny, any, any)).captured;
      expect((captured.first as List).length, 1);
    });

    test('skips cloud entirely when all rows match keywords', () async {
      final contexts = [
        createTestCategoryContext(payee: 'Starbucks'),
        createTestCategoryContext(payee: 'Grab'),
      ];
      final results = await pipeline.suggestBatch(contexts);

      expect(results[0].first.displayName, 'Food');
      expect(results[1].first.displayName, 'Transportation');
      verifyNever(mockAIService.categorizeBatch(any, any, any));
    });
  });
}
