import 'package:equatable/equatable.dart';

class CategorySuggestion extends Equatable {
  final String account;
  final double confidence;

  const CategorySuggestion({
    required this.account,
    required this.confidence,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    return CategorySuggestion(
      account: json['account'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'confidence': confidence,
    };
  }

  bool get isHighConfidence => confidence > 0.8;

  /// Derives a display name from the account path.
  /// e.g., 'Expenses:Food' → 'Food', 'Income:Salary' → 'Salary'
  String get displayName {
    final parts = account.split(':');
    return parts.length > 1 ? parts.last : account;
  }

  @override
  List<Object?> get props => [account, confidence];
}
