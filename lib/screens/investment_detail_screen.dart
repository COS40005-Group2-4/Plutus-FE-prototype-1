import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_model.dart';
import '../models/investment_price_point.dart';
import '../models/investment_sale.dart';
import '../services/interfaces/i_investment_service.dart';
import '../services/investment_metrics_service.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
import '../widgets/chart_theme.dart';
import '../widgets/core/app_card.dart';
import '../widgets/core/metric_delta.dart';
import '../widgets/sell_investment_dialog.dart';

/// Detail view for a single investment: header metrics, price-point history,
/// sales history, and actions (update value, sell).
class InvestmentDetailScreen extends ConsumerStatefulWidget {
  final String investmentId;
  const InvestmentDetailScreen({super.key, required this.investmentId});

  @override
  ConsumerState<InvestmentDetailScreen> createState() => _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState extends ConsumerState<InvestmentDetailScreen> {
  final IInvestmentService _service = sl<IInvestmentService>();

  InvestmentModel? _investment;
  List<InvestmentPricePoint> _pricePoints = const [];
  List<InvestmentSale> _sales = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _service.getInvestmentList(forceRefresh: true);
      final inv = all.firstWhere((i) => i.id == widget.investmentId);
      final points = await _service.getPricePoints(widget.investmentId);
      final sales = await _service.getSales(widget.investmentId);
      if (!mounted) return;
      setState(() {
        _investment = inv;
        _pricePoints = points;
        _sales = sales;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Build the cashflow series used by XIRR: purchase → sales → terminal.
  XirrResult _computeXirr(InvestmentModel inv) {
    final flows = <CashFlow>[
      CashFlow(inv.purchaseDate, -inv.purchaseValue),
      for (final s in _sales) CashFlow(s.date, s.proceeds),
    ];
    if (!inv.isClosed && inv.quantity > 0 && inv.currentPrice != null) {
      flows.add(CashFlow(DateTime.now(), inv.quantity * inv.currentPrice!));
    }
    return InvestmentMetricsService.computeXirr(flows);
  }

  Future<void> _showUpdateValueSheet() async {
    final inv = _investment;
    if (inv == null) return;
    final l = AppLocalizations.of(context);
    final priceController = TextEditingController(
      text: inv.currentPrice?.toStringAsFixed(2) ?? '',
    );
    final noteController = TextEditingController();
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.investmentUpdateValue,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l.investmentUpdateValueSubtitle,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(labelText: l.investmentValuePrice),
                      validator: (v) {
                        final p = double.tryParse((v ?? '').trim());
                        if (p == null || p <= 0) return l.investmentGreaterThanZero;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setSheetState(() => date = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: l.investmentValueDate),
                        child: Text(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(labelText: l.investmentValueNote),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l.cancel),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final price = double.parse(priceController.text.trim());
                            await _service.addPricePoint(
                              investmentId: inv.id,
                              date: date,
                              price: price,
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          },
                          child: Text(l.save),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).investmentValueSaved)),
      );
      await _load();
    }
  }

  Future<void> _showSellDialog() async {
    final inv = _investment;
    if (inv == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => SellInvestmentDialog(
        investment: inv,
        onConfirm: ({
          required quantity,
          required pricePerUnit,
          required date,
          required cashAccount,
          notes,
        }) async {
          await _service.recordSale(
            investmentId: inv.id,
            quantity: quantity,
            pricePerUnit: pricePerUnit,
            date: date,
            cashAccount: cashAccount,
            notes: notes,
          );
        },
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).investmentSaleRecorded)),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inv = _investment;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      inv?.assetName ?? '',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(l)),
          ],
        ),
      ),
      floatingActionButton: (inv != null && !inv.isClosed)
          ? Wrap(
              direction: Axis.vertical,
              spacing: AppSpacing.sm,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'inv_update_value',
                  onPressed: _showUpdateValueSheet,
                  icon: const Icon(Icons.refresh),
                  label: Text(l.investmentUpdateValue),
                ),
                FloatingActionButton.extended(
                  heroTag: 'inv_sell',
                  onPressed: _showSellDialog,
                  backgroundColor: context.tokens.brandNavy,
                  icon: const Icon(Icons.sell, color: Colors.white),
                  label: Text(l.investmentSell, style: const TextStyle(color: Colors.white)),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody(AppLocalizations l) {
    final PlutusTokens t = context.tokens;
    final brightness = Theme.of(context).brightness;
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: t.brandNavy),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: t.error.text)));
    }
    final inv = _investment!;
    final symbol = inv.getCurrencySymbol();
    final irrMeaningful = InvestmentMetricsService.isIrrMeaningful(
      firstCashFlowDate: inv.purchaseDate,
      asOf: DateTime.now(),
    );
    final xirr = irrMeaningful ? _computeXirr(inv) : null;
    final roi = InvestmentMetricsService.computeRoi(
      currentValue: inv.getCurrentValue(),
      costBasis: inv.totalCostBasis,
    );
    final positive = t.success.text;
    final negative = t.error.text;
    final isUp = roi >= 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Fixed-navy hero card (Locked call #4): current value + ROI chip.
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: t.heroSurface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: t.heroBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.investmentCurrentValue.toUpperCase(),
                style: AppTextStyles.overlineStyle.copyWith(color: t.heroLabel),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$symbol${inv.getCurrentValue().toStringAsFixed(2)}',
                style: AppTextStyles.numericStyle.copyWith(
                  fontSize: AppTextStyles.displaySmall,
                  color: const Color(0xFFEDF0F7),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              MetricDelta(percent: roi * 100, decimals: 2),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inv.isClosed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    l.investmentClosedOn(
                      '${inv.closedAt?.year}-${inv.closedAt?.month.toString().padLeft(2, '0')}-${inv.closedAt?.day.toString().padLeft(2, '0')}',
                    ),
                    style: TextStyle(color: t.error.text, fontWeight: FontWeight.w600),
                  ),
                ),
              _MetricRow(label: l.investmentQuantityHeld, value: inv.quantity.toString()),
              _MetricRow(
                label: l.investmentAvgUnitCost,
                value: '$symbol${inv.averageUnitCost.toStringAsFixed(4)}',
              ),
              _MetricRow(
                label: l.investmentMetricRoi,
                value: '${(roi * 100).toStringAsFixed(2)}%',
                color: isUp ? positive : negative,
              ),
              if (xirr != null && xirr.converged && xirr.rate != null)
                _MetricRow(
                  label: l.investmentMetricXirr,
                  value: '${(xirr.rate! * 100).toStringAsFixed(2)}%',
                  color: xirr.rate! >= 0 ? positive : negative,
                )
              else if (!irrMeaningful)
                _MetricRow(
                  label: l.investmentMetricXirr,
                  value: l.investmentMetricHeldUnderYear,
                )
              else
                _MetricRow(
                  label: l.investmentMetricXirr,
                  value: l.investmentMetricIrrUnavailable,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.investmentPriceHistoryTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_pricePoints.length >= 2) ...[
          AppCard(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SizedBox(
              height: 180,
              child: _buildPriceChart(t, inv, brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _pricePoints.isEmpty
            ? Text(l.investmentPriceHistoryEmpty)
            : Column(
                children: _pricePoints.reversed
                    .map((p) => Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: t.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}',
                                style: TextStyle(color: t.textSecondary),
                              ),
                              Text(
                                '$symbol${p.price.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.w600, color: t.text),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.investmentSalesTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        _sales.isEmpty
            ? Text(l.investmentSalesEmpty)
            : Column(
                children: _sales.reversed
                    .map((s) => Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: t.border)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: t.textSecondary),
                                  ),
                                  Text(
                                    '${s.quantity} @ $symbol${s.pricePerUnit.toStringAsFixed(2)}',
                                    style: TextStyle(color: t.text),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${s.realizedGain >= 0 ? l.investmentSellRealizedGain : l.investmentSellRealizedLoss}: $symbol${s.realizedGain.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: s.realizedGain >= 0 ? t.success.text : t.error.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
        const SizedBox(height: 80),
      ],
    );
  }

  /// Price-history line chart (Locked call #5): the navy price line over
  /// the same price points rendered as rows below, plus a dashed gold
  /// reference line at the average unit cost. Only called when there are
  /// >= 2 price points.
  Widget _buildPriceChart(PlutusTokens t, InvestmentModel inv, Brightness brightness) {
    final spots = <FlSpot>[
      for (int i = 0; i < _pricePoints.length; i++)
        FlSpot(i.toDouble(), _pricePoints[i].price),
    ];

    double minY = spots.first.y;
    double maxY = spots.first.y;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }

    // Average unit cost — guard against a zero/negative quantity (fully
    // closed positions) so this never divides by zero.
    final double? avgUnitCost =
        inv.quantity > 0 ? inv.purchaseValue / inv.quantity : null;
    if (avgUnitCost != null) {
      if (avgUnitCost < minY) minY = avgUnitCost;
      if (avgUnitCost > maxY) maxY = avgUnitCost;
    }
    final double range = maxY - minY;
    final double pad = range > 0 ? range * 0.1 : (maxY.abs() * 0.1 + 1);

    final Color lineColor = t.chartCategorical.first;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: PlutusChartStyle.hiddenAxisTitles(),
          rightTitles: PlutusChartStyle.hiddenAxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                final int len = _pricePoints.length;
                if (idx < 0 || idx >= len) return const SizedBox.shrink();
                final int midIdx = len ~/ 2;
                if (idx != 0 && idx != midIdx && idx != len - 1) {
                  return const SizedBox.shrink();
                }
                final DateTime d = _pricePoints[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}',
                    style: TextStyle(color: t.textMuted, fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                return Text(
                  PlutusChartStyle.formatCompactCurrency(value),
                  style: TextStyle(color: t.textMuted, fontSize: 9),
                );
              },
            ),
          ),
        ),
        gridData: PlutusChartStyle.defaultGridData(maxValue: maxY - minY, brightness: brightness),
        borderData: PlutusChartStyle.lineBorderData(brightness: brightness),
        extraLinesData: avgUnitCost == null
            ? null
            : ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: avgUnitCost,
                    color: t.chartCategorical[1],
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                ],
              ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: lineColor,
            barWidth: 1.5,
            dotData: FlDotData(
              show: spots.length < 30,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: lineColor,
                  strokeWidth: 1,
                  strokeColor: t.surface,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
