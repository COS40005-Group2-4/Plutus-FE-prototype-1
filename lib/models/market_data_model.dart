class MarketData {
  final double currentPrice;
  final double priceChangePercent24h;
  final double high24h;
  final double low24h;
  final double? marketCap;
  final double? volume;

  const MarketData({
    required this.currentPrice,
    required this.priceChangePercent24h,
    required this.high24h,
    required this.low24h,
    this.marketCap,
    this.volume,
  });
}
