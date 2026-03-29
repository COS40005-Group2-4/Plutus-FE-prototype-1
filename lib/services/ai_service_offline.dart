import '../models/ai/category_suggestion.dart';
import '../models/ai/correction.dart';
import '../models/transaction_model.dart';
import 'interfaces/i_ai_service.dart';

class AIServiceOffline implements IAIService {
  @override
  Future<CategorySuggestion?> categorizeTransaction(
    Transaction transaction,
    List<String> accounts,
    List<Correction> corrections,
  ) async {
    return null;
  }
}
