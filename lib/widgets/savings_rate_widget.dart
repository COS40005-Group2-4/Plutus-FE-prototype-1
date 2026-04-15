import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../transaction_service.dart';
import '../models/transaction_model.dart';
import '../providers/auth_notifier.dart';
import '../providers/settings_notifier.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'glass_container.dart';
import 'chart_theme.dart';

class SavingsRateWidget extends ConsumerStatefulWidget {
  const SavingsRateWidget({super.key});

  @override
  ConsumerState<SavingsRateWidget> createState() => _SavingsRateWidgetState();
}

class _SavingsRateWidgetState extends ConsumerState<SavingsRateWidget> {
  late TransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _transactionService.setCurrentUser(currentUserId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  Widget _buildStreamContent(BuildContext context, SettingsState settings) {
    return StreamBuilder<List<Transaction>>(
      stream: _transactionService.transactionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context).savingsNoData, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          );
        }
        return _SavingsRateContent(
          key: ValueKey('savings_${settings.currency.code}'),
          transactions: snapshot.data!,
          settings: settings,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    return LayoutBuilder(
          builder: (context, outerConstraints) {
            final bool hasBoundedHeight = outerConstraints.maxHeight.isFinite;
            return GlassContainer(
              color: AppColors.savingsAccent,
              opacity: 0.2,
              borderRadius: AppRadius.lg,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.savings, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).savingsRate,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: AppLocalizations.of(context).widgetHelpSavingsRate,
                        child: Icon(
                          Icons.help_outline,
                          size: 14,
                          color: AppColors.textTertiary(Theme.of(context).brightness),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (hasBoundedHeight)
                    Expanded(
                      child: _buildStreamContent(context, settings),
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: _buildStreamContent(context, settings),
                    ),
                ],
              ),
            );
          },
        );
  }
}

class _SavingsRateContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsState settings;

  const _SavingsRateContent({
    super.key,
    required this.transactions,
    required this.settings,
  });

  @override
  State<_SavingsRateContent> createState() => _SavingsRateContentState();
}

class _SavingsRateContentState extends State<_SavingsRateContent> {
  final CurrencyService _currencyService = CurrencyService();
  double _currentRate = 0;
  double _currentAbsoluteSavings = 0;
  double _currentIncome = 0;
  double _currentExpense = 0;
  double _momChange = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateSavingsRate();
  }

  @override
  void didUpdateWidget(_SavingsRateContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.settings.currency != widget.settings.currency) {
      _calculateSavingsRate();
    }
  }

  Future<void> _calculateSavingsRate() async {
    setState(() => _isLoading = true);

    final targetCurrency = widget.settings.currency.code.toUpperCase();
    final Map<String, double> monthlyIncome = {};
    final Map<String, double> monthlyExpense = {};

    for (var tx in widget.transactions) {
      final key = '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}';
      double amount = tx.totalAmount;
      final source = tx.currency.toUpperCase();
      if (source != targetCurrency) {
        try {
          amount = await _currencyService.convert(amount: tx.totalAmount, fromCurrency: source, toCurrency: targetCurrency);
        } catch (_) {}
      }
      if (tx.isExpense) {
        monthlyExpense[key] = (monthlyExpense[key] ?? 0) + amount;
      } else {
        monthlyIncome[key] = (monthlyIncome[key] ?? 0) + amount;
      }
    }

    final allKeys = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList()..sort();

    // Compute rate for each month
    double currentRate = 0;
    double previousRate = 0;
    double lastIncome = 0;
    double lastExpense = 0;

    for (int i = 0; i < allKeys.length; i++) {
      final income = monthlyIncome[allKeys[i]] ?? 0;
      final expense = monthlyExpense[allKeys[i]] ?? 0;
      final rate = income > 0 ? ((income - expense) / income * 100).clamp(-100.0, 100.0) : 0.0;

      if (i == allKeys.length - 2) {
        previousRate = rate;
      }
      if (i == allKeys.length - 1) {
        currentRate = rate;
        lastIncome = income;
        lastExpense = expense;
      }
    }

    final absoluteSavings = lastIncome - lastExpense;
    final momChange = allKeys.length >= 2 ? currentRate - previousRate : 0.0;

    if (mounted) {
      setState(() {
        _currentRate = currentRate;
        _currentAbsoluteSavings = absoluteSavings;
        _currentIncome = lastIncome;
        _currentExpense = lastExpense;
        _momChange = momChange;
        _isLoading = false;
      });
    }
  }

  Color _getRateColor(double rate, Brightness brightness) {
    if (rate >= 20) return AppColors.positive(brightness);
    if (rate >= 10) return AppColors.warning;
    return AppColors.negative(brightness);
  }

  String _getStatusText(double rate, AppLocalizations l10n) {
    if (rate >= 20) return l10n.savingsOnTrack;
    if (rate >= 10) return l10n.savingsAlmostThere;
    return l10n.savingsBelowTarget;
  }

  IconData _getStatusIcon(double rate) {
    if (rate >= 20) return Icons.check_circle;
    if (rate >= 10) return Icons.trending_flat;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final rateColor = _getRateColor(_currentRate, brightness);
    final currency = widget.settings.currency;
    final symbol = currency.symbol;
    final momColor = _momChange >= 0 ? AppColors.positive(brightness) : AppColors.negative(brightness);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zone 2 — Headline + Status Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: rateColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '= $symbol${PlutusChartStyle.formatCompactCurrency(_currentAbsoluteSavings)} ${l10n.savingsSavedThisMonth}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: rateColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(_currentRate), size: 14, color: rateColor),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(_currentRate, l10n),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: rateColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Zone 3 — Progress Bar toward 20% target
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.savingsProgressLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
                Text(
                  l10n.savingsRuleLabel,
                  style: const TextStyle(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_currentRate / 20.0).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: rateColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_currentRate > 20)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${(_currentRate - 20).toStringAsFixed(1)}% over target',
                  style: const TextStyle(fontSize: 9, color: Colors.white54),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Zone 4 — Income / Expenses / Saved breakdown
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$symbol${PlutusChartStyle.formatCompactCurrency(_currentIncome)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.positive(brightness),
                      ),
                    ),
                    Text(
                      l10n.savingsIncomeLabel,
                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$symbol${PlutusChartStyle.formatCompactCurrency(_currentExpense)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.negative(brightness),
                      ),
                    ),
                    Text(
                      l10n.savingsExpensesLabel,
                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$symbol${PlutusChartStyle.formatCompactCurrency(_currentAbsoluteSavings)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.savingsAccent,
                      ),
                    ),
                    Text(
                      l10n.savingsSavedLabel,
                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // MoM Delta footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _momChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: momColor,
            ),
            const SizedBox(width: 2),
            Text(
              '${_momChange >= 0 ? '+' : ''}${_momChange.toStringAsFixed(1)} pts ${l10n.savingsVsLastMonth}',
              style: TextStyle(
                fontSize: 11,
                color: momColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
