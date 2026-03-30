import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../transaction_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class CashflowWidget extends StatefulWidget {
  const CashflowWidget({super.key});

  @override
  State<CashflowWidget> createState() => _CashflowWidgetState();
}

class _CashflowWidgetState extends State<CashflowWidget> {
  late TransactionService _transactionService;
  bool _isMonthlyView = true;
  DateTime _selectedDate = DateTime.now();
  bool _showBarChart = true;
  bool _showComparison = false;
  DateTime? _comparisonDate;

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
          color: AppColors.borderDark,
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Transaction>>(
                  stream: _transactionService.transactionStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context).noTransactionsFound,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      );
                    }

                    final transactions = _filterTransactions(snapshot.data!);
                    final comparisonTransactions = _showComparison && _comparisonDate != null
                        ? _filterComparisonTransactions(snapshot.data!)
                        : null;

                    return _CashflowContent(
                      key: ValueKey('cashflow_${settings.currency.code}_${_selectedDate}_${_isMonthlyView}_${_showBarChart}_${_showComparison}_$_comparisonDate'),
                      transactions: transactions,
                      comparisonTransactions: comparisonTransactions,
                      settings: settings,
                      isMonthlyView: _isMonthlyView,
                      selectedDate: _selectedDate,
                      comparisonDate: _comparisonDate,
                      showBarChart: _showBarChart,
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cash Flow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMonthlyView = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isMonthlyView ? Colors.white.withValues(alpha:0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Month',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: _isMonthlyView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _isMonthlyView = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_isMonthlyView ? Colors.white.withValues(alpha:0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Year',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: !_isMonthlyView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showBarChart ? Icons.bar_chart : Icons.show_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showBarChart = !_showBarChart),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _showBarChart ? 'Switch to Line Chart' : 'Switch to Bar Chart',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showComparison ? Icons.compare_arrows : Icons.compare,
                    color: _showComparison ? Colors.greenAccent : Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showComparison = !_showComparison;
                      if (_showComparison && _comparisonDate == null) {
                        _comparisonDate = DateTime(_selectedDate.year - 1, _selectedDate.month);
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Compare Years',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  if (_isMonthlyView) {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                  } else {
                    _selectedDate = DateTime(_selectedDate.year - 1);
                  }
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              _isMonthlyView
                  ? '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}'
                  : '${_selectedDate.year}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  if (_isMonthlyView) {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                  } else {
                    _selectedDate = DateTime(_selectedDate.year + 1);
                  }
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        if (_showComparison && _comparisonDate != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'vs ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDialog<int>(
                    context: context,
                    builder: (context) => _YearPickerDialog(
                      initialYear: _comparisonDate!.year,
                      minYear: 2000,
                      maxYear: 2100,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _comparisonDate = DateTime(picked, _selectedDate.month);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha:0.5)),
                  ),
                  child: Text(
                    _isMonthlyView
                        ? '${_getMonthName(_comparisonDate!.month)} ${_comparisonDate!.year}'
                        : '${_comparisonDate!.year}',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                onPressed: () => setState(() => _showComparison = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((tx) {
      if (_isMonthlyView) {
        return tx.dateTime.year == _selectedDate.year && tx.dateTime.month == _selectedDate.month;
      } else {
        return tx.dateTime.year == _selectedDate.year;
      }
    }).toList();
  }

  List<Transaction> _filterComparisonTransactions(List<Transaction> transactions) {
    if (_comparisonDate == null) return [];
    return transactions.where((tx) {
      if (_isMonthlyView) {
        return tx.dateTime.year == _comparisonDate!.year && tx.dateTime.month == _comparisonDate!.month;
      } else {
        return tx.dateTime.year == _comparisonDate!.year;
      }
    }).toList();
  }
}

// Year Picker Dialog
class _YearPickerDialog extends StatelessWidget {
  final int initialYear;
  final int minYear;
  final int maxYear;

  const _YearPickerDialog({
    required this.initialYear,
    required this.minYear,
    required this.maxYear,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).cashflowSelectYear),
      content: SizedBox(
        width: 300,
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: maxYear - minYear + 1,
          itemBuilder: (context, index) {
            final year = minYear + index;
            final isSelected = year == initialYear;
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(year),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$year',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
