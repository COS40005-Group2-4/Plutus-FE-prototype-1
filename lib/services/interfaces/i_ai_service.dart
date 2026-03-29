import '../../models/ai/category_suggestion.dart';
import '../../models/ai/correction.dart';
import '../../models/transaction_model.dart';

abstract class IAIService {
  Future<CategorySuggestion?> categorizeTransaction(
    Transaction transaction,
    List<String> accounts,
    List<Correction> corrections,
  );

  Future<List<CategorySuggestion?>> categorizeBatch(
    List<Transaction> transactions,
    List<String> accounts,
    List<Correction> corrections,
  );
}
