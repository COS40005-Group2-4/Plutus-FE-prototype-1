import 'package:equatable/equatable.dart';

/// A realized partial or full sale of an investment, with the realized gain
/// computed against the investment's running average cost basis.
class InvestmentSale extends Equatable {
  final int? id;
  final String investmentId;
  final int? transactionId;
  final DateTime date;
  final double quantity;
  final double pricePerUnit;
  final double costBasisRelieved;
  final double realizedGain;

  const InvestmentSale({
    this.id,
    required this.investmentId,
    this.transactionId,
    required this.date,
    required this.quantity,
    required this.pricePerUnit,
    required this.costBasisRelieved,
    required this.realizedGain,
  });

  double get proceeds => quantity * pricePerUnit;

  @override
  List<Object?> get props => [
        id,
        investmentId,
        transactionId,
        date,
        quantity,
        pricePerUnit,
        costBasisRelieved,
        realizedGain,
      ];

  factory InvestmentSale.fromMap(Map<String, dynamic> map) {
    return InvestmentSale(
      id: map['id'] as int?,
      investmentId: map['investment_id'] as String,
      transactionId: map['transaction_id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch((map['date'] as int) * 1000),
      quantity: (map['quantity'] as num).toDouble(),
      pricePerUnit: (map['price_per_unit'] as num).toDouble(),
      costBasisRelieved: (map['cost_basis_relieved'] as num).toDouble(),
      realizedGain: (map['realized_gain'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'investment_id': investmentId,
      'transaction_id': transactionId,
      'date': date.millisecondsSinceEpoch ~/ 1000,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'cost_basis_relieved': costBasisRelieved,
      'realized_gain': realizedGain,
    };
  }
}
