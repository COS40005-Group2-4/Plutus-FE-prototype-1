import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../providers/auth_notifier.dart';
import '../services/interfaces/interfaces.dart';
import '../di/service_locator.dart';
import '../providers/settings_notifier.dart';
import '../services/currency_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import 'core/app_card.dart';
import 'chart_theme.dart';

class ExpenseBreakdownChartWidget extends ConsumerStatefulWidget {
  const ExpenseBreakdownChartWidget({super.key});

  @override
  ConsumerState<ExpenseBreakdownChartWidget> createState() => _ExpenseBreakdownChartWidgetState();
}

class _ExpenseBreakdownChartWidgetState extends ConsumerState<ExpenseBreakdownChartWidget> {
  late ITransactionService _transactionService;
  int _viewMode = 0; // 0 = Month, 1 = Year
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _transactionService = sl<ITransactionService>();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _transactionService.setCurrentUser(currentUserId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((tx) {
      if (_viewMode == 0) {
        return tx.dateTime.year == _selectedDate.year && tx.dateTime.month == _selectedDate.month;
      } else {
        return tx.dateTime.year == _selectedDate.year;
      }
    }).toList();
  }

  Map<String, double> _calculateCategoryExpenses(List<Transaction> transactions) {
    final Map<String, double> categoryTotals = {};
    for (final tx in transactions) {
      if (!tx.isExpense) continue;
      String category = 'Other';
      for (final posting in tx.postings) {
        final account = posting.account.toLowerCase();
        if (account.startsWith('expenses:')) {
          final parts = posting.account.split(':');
          if (parts.length > 1) category = parts[1];
          break;
        }
      }
      categoryTotals[category] = (categoryTotals[category] ?? 0) + tx.totalAmount;
    }
    return categoryTotals;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final PlutusTokens t = context.tokens;
    return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: StreamBuilder<List<Transaction>>(
                  stream: _transactionService.transactionStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: t.text));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context).noTransactionsFound,
                          style: TextStyle(color: t.text, fontSize: 14),
                        ),
                      );
                    }
                    final filtered = _filterTransactions(snapshot.data!);
                    final categoryData = _calculateCategoryExpenses(filtered);
                    return _ExpenseBreakdownContent(
                      key: ValueKey('expbreakdown_${settings.currency.code}_${_selectedDate}_$_viewMode'),
                      categoryData: categoryData,
                      settings: settings,
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildHeader(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Expense Breakdown',
                style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: AppLocalizations.of(context).widgetHelpExpenseBreakdown,
              child: Icon(
                Icons.help_outline,
                size: 14,
                color: t.textMuted,
              ),
            ),
            Row(
              children: [
                _buildToggle('Month', 0),
                const SizedBox(width: AppSpacing.xs),
                _buildToggle('Year', 1),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: t.text, size: 20),
              onPressed: () => setState(() {
                _selectedDate = _viewMode == 0
                    ? DateTime(_selectedDate.year, _selectedDate.month - 1)
                    : DateTime(_selectedDate.year - 1);
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              _viewMode == 0
                  ? '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}'
                  : '${_selectedDate.year}',
              style: TextStyle(
                  color: t.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: t.text, size: 20),
              onPressed: () => setState(() {
                _selectedDate = _viewMode == 0
                    ? DateTime(_selectedDate.year, _selectedDate.month + 1)
                    : DateTime(_selectedDate.year + 1);
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggle(String label, int mode) {
    final PlutusTokens t = context.tokens;
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? t.surfaceSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? t.text : t.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _ExpenseBreakdownContent extends StatefulWidget {
  final Map<String, double> categoryData;
  final SettingsState settings;

  const _ExpenseBreakdownContent({
    super.key,
    required this.categoryData,
    required this.settings,
  });

  @override
  State<_ExpenseBreakdownContent> createState() => _ExpenseBreakdownContentState();
}

class _ExpenseBreakdownContentState extends State<_ExpenseBreakdownContent> {
  final CurrencyService _currencyService = CurrencyService();
  Map<String, double> _convertedData = {};
  bool _isLoading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _convertData();
  }

  @override
  void didUpdateWidget(_ExpenseBreakdownContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryData != widget.categoryData ||
        oldWidget.settings.currency != widget.settings.currency) {
      _convertData();
    }
  }

  Future<void> _convertData() async {
    setState(() => _isLoading = true);
    final converted = <String, double>{};
    for (final entry in widget.categoryData.entries) {
      double amount = entry.value;
      final target = widget.settings.currency.code.toUpperCase();
      try {
        amount = await _currencyService.convert(
          amount: entry.value,
          fromCurrency: widget.settings.currency.code,
          toCurrency: target,
        );
      } catch (_) {}
      converted[entry.key] = amount;
    }
    if (mounted) {
      setState(() {
        _convertedData = converted;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: t.text));
    }

    if (_convertedData.isEmpty) {
      return Center(
        child: Text(
          'No expenses in this period',
          style: TextStyle(color: t.textSecondary, fontSize: 12),
        ),
      );
    }

    final sorted = _convertedData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (sum, e) => sum + e.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: (constraints.maxHeight * 0.5).clamp(120.0, 180.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(sorted.length, (i) {
                          final isTouched = i == _touchedIndex;
                          return PieChartSectionData(
                            color: t.chartCategorical[i % 6].withValues(alpha:0.8),
                            value: sorted[i].value,
                            title: isTouched ? '${(sorted[i].value / total * 100).toStringAsFixed(0)}%' : '',
                            radius: isTouched ? 40 : 32,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }),
                      ),
                    ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          PlutusChartStyle.formatCompactCurrency(total),
                          style: TextStyle(
                              color: t.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.settings.currency.symbol,
                          style: TextStyle(
                              color: t.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...sorted.take(6).toList().asMap().entries.map((mapEntry) {
                final i = mapEntry.key;
                final entry = mapEntry.value;
                final pct = (entry.value / total * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: t.chartCategorical[i % 6],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                              color: t.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style:
                            TextStyle(color: t.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _currencyService.formatCurrency(amount: entry.value, currencyCode: widget.settings.currency.code),
                        style: TextStyle(
                            color: t.text,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
