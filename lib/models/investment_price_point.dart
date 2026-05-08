import 'package:equatable/equatable.dart';

/// A user-recorded valuation of an investment at a point in time.
class InvestmentPricePoint extends Equatable {
  final int? id;
  final String investmentId;
  final DateTime date;
  final double price;
  final String? note;

  const InvestmentPricePoint({
    this.id,
    required this.investmentId,
    required this.date,
    required this.price,
    this.note,
  });

  @override
  List<Object?> get props => [id, investmentId, date, price, note];

  factory InvestmentPricePoint.fromMap(Map<String, dynamic> map) {
    return InvestmentPricePoint(
      id: map['id'] as int?,
      investmentId: map['investment_id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch((map['date'] as int) * 1000),
      price: (map['price'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'investment_id': investmentId,
      'date': date.millisecondsSinceEpoch ~/ 1000,
      'price': price,
      'note': note,
    };
  }
}
