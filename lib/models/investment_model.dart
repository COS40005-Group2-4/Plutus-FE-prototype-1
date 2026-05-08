import 'package:equatable/equatable.dart';

enum AssetType {
  stock,
  bond,
  crypto,
  other,
}

enum Currency {
  vnd,
  usd,
  eur,
}

enum InvestmentStatus { active, closed }

class InvestmentModel extends Equatable {
  final String id;
  final AssetType assetType;
  final String assetName; // Symbol for stock/crypto, or custom name for "other"
  final double quantity;
  final double purchaseValue; // Original purchase value (immutable, for reporting)
  final double totalCostBasis; // Running cost basis after partial sales (avg-cost method)
  final Currency currency;
  final DateTime purchaseDate;
  final double? currentPrice; // Current price per unit in original currency
  final List<PriceHistoryPoint>? priceHistory;
  final InvestmentStatus status;
  final DateTime? closedAt;

  const InvestmentModel({
    required this.id,
    required this.assetType,
    required this.assetName,
    required this.quantity,
    required this.purchaseValue,
    double? totalCostBasis,
    required this.currency,
    required this.purchaseDate,
    this.currentPrice,
    this.priceHistory,
    this.status = InvestmentStatus.active,
    this.closedAt,
  }) : totalCostBasis = totalCostBasis ?? purchaseValue;

  /// Average unit cost based on the current cost basis and quantity.
  /// Returns 0 when quantity is zero (closed position).
  double get averageUnitCost {
    if (quantity <= 0) return 0;
    return totalCostBasis / quantity;
  }

  bool get isClosed => status == InvestmentStatus.closed;

  InvestmentModel copyWith({
    String? id,
    AssetType? assetType,
    String? assetName,
    double? quantity,
    double? purchaseValue,
    double? totalCostBasis,
    Currency? currency,
    DateTime? purchaseDate,
    double? currentPrice,
    List<PriceHistoryPoint>? priceHistory,
    InvestmentStatus? status,
    DateTime? closedAt,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      assetType: assetType ?? this.assetType,
      assetName: assetName ?? this.assetName,
      quantity: quantity ?? this.quantity,
      purchaseValue: purchaseValue ?? this.purchaseValue,
      totalCostBasis: totalCostBasis ?? this.totalCostBasis,
      currency: currency ?? this.currency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      currentPrice: currentPrice ?? this.currentPrice,
      priceHistory: priceHistory ?? this.priceHistory,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        assetType,
        assetName,
        quantity,
        purchaseValue,
        totalCostBasis,
        currency,
        purchaseDate,
        currentPrice,
        priceHistory,
        status,
        closedAt,
      ];

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id') ||
        !json.containsKey('asset_type') ||
        !json.containsKey('asset_name') ||
        !json.containsKey('quantity') ||
        !json.containsKey('purchase_value') ||
        !json.containsKey('currency') ||
        !json.containsKey('purchase_date')) {
      throw ArgumentError('Missing required fields in InvestmentModel JSON');
    }

    final purchaseValue = double.parse(json['purchase_value'].toString());
    return InvestmentModel(
      id: json['id'] as String,
      assetType: _parseAssetType(json['asset_type'] as String),
      assetName: json['asset_name'] as String,
      quantity: double.parse(json['quantity'].toString()),
      purchaseValue: purchaseValue,
      totalCostBasis: json['total_cost_basis'] != null
          ? double.parse(json['total_cost_basis'].toString())
          : purchaseValue,
      currency: _parseCurrency(json['currency'] as String),
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(
        (json['purchase_date'] as int) * 1000,
      ),
      currentPrice: json['current_price'] != null
          ? double.parse(json['current_price'].toString())
          : null,
      priceHistory: json['price_history'] != null
          ? (json['price_history'] as List)
              .map((e) => PriceHistoryPoint.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      status: _parseStatus(json['status'] as String?),
      closedAt: json['closed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['closed_at'] as int) * 1000)
          : null,
    );
  }

  static InvestmentStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'closed':
        return InvestmentStatus.closed;
      case 'active':
      case null:
        return InvestmentStatus.active;
      default:
        return InvestmentStatus.active;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_type': assetType.name,
      'asset_name': assetName,
      'quantity': quantity,
      'purchase_value': purchaseValue,
      'total_cost_basis': totalCostBasis,
      'currency': currency.name,
      'purchase_date': purchaseDate.millisecondsSinceEpoch ~/ 1000,
      if (currentPrice != null) 'current_price': currentPrice,
      if (priceHistory != null)
        'price_history': priceHistory!.map((e) => e.toJson()).toList(),
      'status': status == InvestmentStatus.closed ? 'closed' : 'active',
      if (closedAt != null) 'closed_at': closedAt!.millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Returns the total current value (quantity * current price)
  double getCurrentValue() {
    if (currentPrice == null) return purchaseValue;
    return quantity * currentPrice!;
  }

  /// Returns the gain/loss amount versus the running cost basis (avg-cost method).
  double getGainLoss() {
    return getCurrentValue() - totalCostBasis;
  }

  /// Returns the gain/loss percentage versus the running cost basis.
  double getGainLossPercent() {
    if (totalCostBasis == 0) return 0;
    return (getGainLoss() / totalCostBasis) * 100;
  }

  /// Returns true if investment has positive returns
  bool isPositiveReturn() {
    return getGainLoss() >= 0;
  }

  /// Returns formatted gain/loss percentage with + or - sign
  String getFormattedGainLoss() {
    final percent = getGainLossPercent();
    return '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(2)}%';
  }

  /// Returns currency symbol
  String getCurrencySymbol() {
    switch (currency) {
      case Currency.vnd:
        return '₫';
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
    }
  }

  static AssetType _parseAssetType(String type) {
    switch (type.toLowerCase()) {
      case 'stock':
        return AssetType.stock;
      case 'bond':
        return AssetType.bond;
      case 'crypto':
        return AssetType.crypto;
      case 'other':
        return AssetType.other;
      default:
        throw ArgumentError('Invalid asset type: $type');
    }
  }

  static Currency _parseCurrency(String curr) {
    switch (curr.toLowerCase()) {
      case 'vnd':
        return Currency.vnd;
      case 'usd':
        return Currency.usd;
      case 'eur':
        return Currency.eur;
      default:
        throw ArgumentError('Invalid currency: $curr');
    }
  }
}

class PriceHistoryPoint extends Equatable {
  final DateTime date;
  final double price;

  const PriceHistoryPoint({
    required this.date,
    required this.price,
  });

  @override
  List<Object?> get props => [date, price];

  factory PriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PriceHistoryPoint(
      date: DateTime.fromMillisecondsSinceEpoch((json['date'] as int) * 1000),
      price: double.parse(json['price'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch ~/ 1000,
      'price': price,
    };
  }
}
