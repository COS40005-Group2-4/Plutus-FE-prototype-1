import '../../models/ai/category_suggestion.dart';
import '../../models/ai/category_context.dart';

abstract class IAICategoryPipeline {
  Future<List<CategorySuggestion>> suggest(CategoryContext context);
  Stream<List<CategorySuggestion>> suggestStream(CategoryContext context);
  Future<List<List<CategorySuggestion>>> suggestBatch(List<CategoryContext> contexts);
}
