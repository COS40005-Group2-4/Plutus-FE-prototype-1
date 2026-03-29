import 'package:equatable/equatable.dart';

class CategoryContext extends Equatable {
  final String? payee;
  final String? description;
  final double? amount;
  final String? currency;
  final List<Map<String, dynamic>>? items;
  final String? ocrText;

  const CategoryContext({
    this.payee,
    this.description,
    this.amount,
    this.currency,
    this.items,
    this.ocrText,
  });

  @override
  List<Object?> get props => [payee, description, amount, currency, items, ocrText];
}
