import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transaction_service.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class SpendingHeatmapWidget extends StatefulWidget {
  const SpendingHeatmapWidget({super.key});

  @override
  State<SpendingHeatmapWidget> createState() => _SpendingHeatmapWidgetState();
}

class _SpendingHeatmapWidgetState extends State<SpendingHeatmapWidget> {
  late TransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassContainer(
          color: AppColors.heatmapAccent,
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_view_week, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Spending Heatmap',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Last 12 weeks · tap a day to inspect',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Transaction>>(
                  stream: _transactionService.transactionStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No spending data',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      );
                    }
                    return _HeatmapContent(
                      key: ValueKey('heatmap_${settings.currency.code}'),
                      transactions: snapshot.data!,
                      settings: settings,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Grid constants
// ---------------------------------------------------------------------------

const int _kWeeks = 12;
const int _kDays = 7; // Mon=0 … Sun=6

/// The Monday that begins the oldest visible week.
DateTime _gridStart() {
  final today = DateTime.now();
  // Monday of the current week
  final currentMonday =
      DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: today.weekday - 1));
  // Go back 11 more weeks
  return currentMonday.subtract(const Duration(days: 77));
}

/// Normalize a DateTime to midnight (strips time component).
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

// ---------------------------------------------------------------------------
// Content widget
// ---------------------------------------------------------------------------

class _HeatmapContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsProvider settings;

  const _HeatmapContent({
    super.key,
    required this.transactions,
    required this.settings,
  });

  @override
  State<_HeatmapContent> createState() => _HeatmapContentState();
}

class _HeatmapContentState extends State<_HeatmapContent> {
  final CurrencyService _currencyService = CurrencyService();

  /// date → total expense amount (display currency)
  Map<DateTime, double> _dailyTotals = {};

  /// date → individual expense transactions with converted amounts (for tooltip)
  Map<DateTime, List<(Transaction, double)>> _dailyTransactions = {};

  double _peakAmount = 0;
  bool _isLoading = true;

  /// Currently tapped date, null = no tooltip shown
  DateTime? _selectedDate;

  late final DateTime _gridStartDate = _gridStart();
  late final DateTime _today = _dateOnly(DateTime.now());

  int _buildGeneration = 0;

  @override
  void initState() {
    super.initState();
    _buildDailyTotals();
  }

  @override
  void didUpdateWidget(_HeatmapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
      _buildDailyTotals();
    }
  }

  Future<void> _buildDailyTotals() async {
    final generation = ++_buildGeneration;
    setState(() => _isLoading = true);

    final target = widget.settings.currency.code.toUpperCase();
    final Map<DateTime, double> totals = {};
    final Map<DateTime, List<(Transaction, double)>> txMap = {};

    for (final tx in widget.transactions) {
      if (!tx.isExpense) continue;
      final day = _dateOnly(tx.dateTime);

      double amount = tx.totalAmount;
      final source = tx.currency.toUpperCase();
      if (source != target) {
        try {
          amount = await _currencyService.convert(
              amount: tx.totalAmount,
              fromCurrency: source,
              toCurrency: target);
        } catch (_) {
          // conversion failed — keep original amount in display currency fallback
        }
      }

      // Bail out if a newer invocation has started
      if (generation != _buildGeneration) return;

      totals[day] = (totals[day] ?? 0) + amount;
      txMap.putIfAbsent(day, () => []).add((tx, amount));
    }

    final peak = totals.values.fold(0.0, (a, b) => a > b ? a : b);

    if (mounted && generation == _buildGeneration) {
      setState(() {
        _dailyTotals = totals;
        _dailyTransactions = txMap;
        _peakAmount = peak;
        _selectedDate = null; // clear stale tooltip on data rebuild
        _isLoading = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Colour helpers
  // -------------------------------------------------------------------------

  static const Color _emptyCell = Color(0xFF111827); // future / no-data
  static const Color _zeroCell = Color(0xFF1E2D3D);  // had data, zero spend
  static const Color _peakCell = Color(0xFFE74C3C);  // highest-spend day

  Color _cellColor(DateTime date) {
    if (date.isAfter(_today)) return _emptyCell;
    final amount = _dailyTotals[date];
    if (amount == null) return _emptyCell;
    if (amount == 0 || _peakAmount == 0) return _zeroCell;
    final intensity = (amount / _peakAmount).clamp(0.0, 1.0);
    return Color.lerp(_zeroCell, _peakCell, intensity)!;
  }

  // -------------------------------------------------------------------------
  // Column header label
  // -------------------------------------------------------------------------

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _columnHeader(int col) {
    final weekMonday = _gridStartDate.add(Duration(days: col * 7));
    if (col == 0) {
      return '${_monthNames[weekMonday.month - 1]} ${weekMonday.day}';
    }
    final prevMonday = _gridStartDate.add(Duration(days: (col - 1) * 7));
    if (weekMonday.month != prevMonday.month) {
      return _monthNames[weekMonday.month - 1];
    }
    return '${weekMonday.day}';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGrid(),
        if (_selectedDate != null) ...[
          const SizedBox(height: 8),
          _buildTooltip(_selectedDate!),
        ],
      ],
    );
  }

  Widget _buildGrid() {
    return Expanded(
      child: Column(
        children: [
          // Column headers (week start dates / month names)
          Row(
            children: [
              const SizedBox(width: 28), // row-label gutter
              ...List.generate(_kWeeks, (col) {
                return Expanded(
                  child: Text(
                    _columnHeader(col),
                    style: const TextStyle(color: Colors.white38, fontSize: 7),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          // Grid rows: Mon … Sun
          Expanded(
            child: Column(
              children: List.generate(_kDays, (row) {
                final rowLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][row];
                return Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          rowLabel,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ...List.generate(_kWeeks, (col) {
                        final date = _gridStartDate
                            .add(Duration(days: col * 7 + row));
                        final isSelected = _selectedDate == date;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate =
                                    _selectedDate == date ? null : date;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: _cellColor(date),
                                borderRadius: BorderRadius.circular(2),
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.white54, width: 1)
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(DateTime date) {
    final txList = _dailyTransactions[date] ?? [];
    final total = _dailyTotals[date] ?? 0;
    final dateStr =
        '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(
                _currencyService.formatCurrency(
                    amount: total,
                    currencyCode: widget.settings.currency.code),
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (txList.isEmpty)
            const Text('No expenses',
                style: TextStyle(color: Colors.white38, fontSize: 10))
          else
            ...txList.take(4).map((entry) {
              final (tx, convertedAmount) = entry;
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx.description,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _currencyService.formatCurrency(
                          amount: convertedAmount,
                          currencyCode: widget.settings.currency.code),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
          if (txList.length > 4)
            Text(
              '+${txList.length - 4} more',
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
        ],
      ),
    );
  }
}
