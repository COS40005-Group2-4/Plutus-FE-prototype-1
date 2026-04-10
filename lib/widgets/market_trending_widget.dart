import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_data_model.dart';
import '../services/interfaces/i_price_api_service.dart';
import '../di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'glass_container.dart';
import 'chart_theme.dart';

class MarketTrendingWidget extends StatefulWidget {
  const MarketTrendingWidget({super.key});

  @override
  State<MarketTrendingWidget> createState() => _MarketTrendingWidgetState();
}

class _MarketTrendingWidgetState extends State<MarketTrendingWidget> {
  static const _symbolKey = 'market_trending_symbol';
  static const _daysKey = 'market_trending_days';

  final _symbolController = TextEditingController();
  String _symbol = 'BTC';
  int _selectedDays = 7;
  MarketData? _marketData;
  List<Map<String, dynamic>> _chartPoints = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final symbol = prefs.getString(_symbolKey) ?? 'BTC';
    final days = prefs.getInt(_daysKey) ?? 7;
    _symbolController.text = symbol;
    setState(() {
      _symbol = symbol;
      _selectedDays = days;
    });
    _fetchData();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_symbolKey, _symbol);
    await prefs.setInt(_daysKey, _selectedDays);
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = sl<IPriceApiService>();
      final results = await Future.wait([
        service.getMarketData(_symbol),
        service.getHistoricalPrices(_symbol, _selectedDays),
      ]);

      final marketData = results[0] as MarketData?;
      final historicalPrices = results[1] as List<Map<String, dynamic>>?;

      if (!mounted) return;

      if (marketData == null) {
        setState(() {
          _isLoading = false;
          _error = 'Symbol not found';
          _marketData = null;
          _chartPoints = [];
        });
        return;
      }

      final points = historicalPrices != null
          ? _downsample(historicalPrices, 60)
          : <Map<String, dynamic>>[];

      setState(() {
        _isLoading = false;
        _marketData = marketData;
        _chartPoints = points;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data';
      });
    }
  }

  List<Map<String, dynamic>> _downsample(List<Map<String, dynamic>> points, int maxPoints) {
    if (points.length <= maxPoints) return points;
    final step = points.length / maxPoints;
    return List.generate(maxPoints, (i) => points[(i * step).floor()]);
  }

  void _onSymbolSubmit(String val) {
    final sym = val.trim().toUpperCase();
    if (sym.isEmpty) return;
    _symbolController.text = sym;
    setState(() => _symbol = sym);
    _savePrefs();
    _fetchData();
  }

  void _onDaysSelected(int days) {
    if (_selectedDays == days) return;
    setState(() => _selectedDays = days);
    _savePrefs();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: AppColors.borderDark,
      opacity: 0.2,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 220;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Market Trending',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: AppLocalizations.of(context).widgetHelpMarketTrending,
                    child: Icon(
                      Icons.help_outline,
                      size: 14,
                      color: AppColors.textTertiary(Theme.of(context).brightness),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 8),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                )
              else if (_marketData != null) ...[
                _buildMetrics(_marketData!),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  Expanded(child: _buildChart()),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _symbolController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Symbol',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              filled: true,
              fillColor: Colors.white.withValues(alpha:0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _onSymbolSubmit,
          ),
        ),
        const SizedBox(width: 8),
        _buildDayButton(7),
        const SizedBox(width: 4),
        _buildDayButton(30),
        const SizedBox(width: 4),
        _buildDayButton(90),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _fetchData,
          child: const Icon(Icons.refresh, color: Colors.white70, size: 18),
        ),
      ],
    );
  }

  Widget _buildDayButton(int days) {
    final selected = _selectedDays == days;
    return GestureDetector(
      onTap: () => _onDaysSelected(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha:0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${days}d',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics(MarketData data) {
    final isPositive = data.priceChangePercent24h >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;
    final changeSign = isPositive ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '\$${_formatPrice(data.currentPrice)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$changeSign${data.priceChangePercent24h.toStringAsFixed(2)}%',
              style: TextStyle(color: changeColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildMetricChip('H', '\$${_formatPrice(data.high24h)}'),
            const SizedBox(width: 8),
            _buildMetricChip('L', '\$${_formatPrice(data.low24h)}'),
            if (data.volume != null) ...[
              const SizedBox(width: 8),
              _buildMetricChip('Vol', PlutusChartStyle.formatCompactCurrency(data.volume!)),
            ],
            if (data.marketCap != null) ...[
              const SizedBox(width: 8),
              _buildMetricChip('MCap', '\$${PlutusChartStyle.formatCompactCurrency(data.marketCap!)}'),
            ],
            if (data.marketCap == null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'MCap: --',
                  style: TextStyle(color: Colors.white.withValues(alpha:0.5), fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withValues(alpha:0.6), fontSize: 10),
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  Widget _buildChart() {
    if (_chartPoints.isEmpty) {
      return const Center(
        child: Text('No chart data', style: TextStyle(color: Colors.white54, fontSize: 12)),
      );
    }

    final data = _marketData!;
    final isPositive = data.priceChangePercent24h >= 0;
    final lineColor = isPositive ? PlutusChartColors.palette[1] : PlutusChartColors.palette[2];

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < _chartPoints.length; i++) {
      final price = (_chartPoints[i]['price'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
      if (price < minY) minY = price;
      if (price > maxY) maxY = price;
    }

    final padding = (maxY - minY) * 0.05;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '\$${_formatPrice(s.y)}',
                const TextStyle(color: Colors.white, fontSize: 10),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: PlutusChartStyle.hiddenAxisTitles(),
          rightTitles: PlutusChartStyle.hiddenAxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                final len = spots.length;
                if (len < 2) return const SizedBox.shrink();
                final midIdx = len ~/ 2;
                if (idx == 0 || idx == midIdx || idx == len - 1) {
                  final ms = (_chartPoints[idx]['date'] as num).toInt();
                  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
                  final label = _formatDate(dt);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                return Text(
                  PlutusChartStyle.formatCompactCurrency(value),
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                );
              },
            ),
          ),
        ),
        gridData: PlutusChartStyle.defaultGridData(maxValue: maxY - minY, brightness: Theme.of(context).brightness),
        borderData: PlutusChartStyle.lineBorderData(brightness: Theme.of(context).brightness),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: lineColor,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha:0.25),
                  lineColor.withValues(alpha:0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(6);
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
