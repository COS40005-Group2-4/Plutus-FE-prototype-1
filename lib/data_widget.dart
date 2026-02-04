import 'package:auto_size_text/auto_size_text.dart';
import 'package:dashboard/dashboard.dart';
import 'storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'transaction_service.dart';
import 'models/transaction_model.dart';
import 'widgets/glass_container.dart';
import 'providers/auth_provider.dart';

const Color blue = Color(0xFF4285F4);
const Color red = Color(0xFFEA4335);
const Color yellow = Color(0xFFFBBC05);
const Color green = Color(0xFF34A853);

class DataWidget extends StatelessWidget {
  DataWidget({super.key, required this.item});

  final ColoredDashboardItem item;

  final Map<String, Widget Function(ColoredDashboardItem i)> _map = {
    "budget": (l) => const BudgetTrackingWidget(),
    "history": (l) => const TransactionHistoryWidget(),
    "import": (l) => const ReportImportWidget(),
    "export": (l) => const ReportExportWidget(),
  };

  @override
  Widget build(BuildContext context) {
    final dataKey = item.data;
    final builder = dataKey != null ? _map[dataKey] : null;
    if (builder == null) {
      return const SizedBox.shrink();
    }
    return builder(item);
  }
}

// Budget Tracking Display Widget
class BudgetTrackingWidget extends StatefulWidget {
  const BudgetTrackingWidget({super.key});

  @override
  State<BudgetTrackingWidget> createState() => _BudgetTrackingWidgetState();
}

class _BudgetTrackingWidgetState extends State<BudgetTrackingWidget> {
  late TransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: blue,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Transaction>>(
        future: _transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          final transactions = snapshot.data!;
          double totalIncome = 0;
          double totalExpense = 0;
          final formatter = NumberFormat("#,##0.00", "en_US");

          for (var transaction in transactions) {
            if (transaction.isExpense) {
              totalExpense += transaction.totalAmount;
            } else {
              totalIncome += transaction.totalAmount;
            }
          }

          final balance = totalIncome - totalExpense;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                'Budget Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GlassContainer(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                opacity: 0.1,
                borderRadius: 8,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Income:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '\$${formatter.format(totalIncome)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expense:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '\$${formatter.format(totalExpense)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${formatter.format(balance)}',
                          style: TextStyle(
                            color: balance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Transaction History Display Widget
class TransactionHistoryWidget extends StatefulWidget {
  const TransactionHistoryWidget({super.key});

  @override
  State<TransactionHistoryWidget> createState() =>
      _TransactionHistoryWidgetState();
}

class _TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  late TransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: green,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<List<Transaction>>(
        future: _transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No transaction history',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            );
          }

          final allTransactions = List<Transaction>.from(snapshot.data!);
          allTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          final transactions = allTransactions.take(10).toList();
          final formatter = NumberFormat("#,##0.00", "en_US");

          return Column(
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isExpense = transaction.isExpense;

                    return GlassContainer(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      color: Colors.white,
                      opacity: 0.1,
                      borderRadius: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  transaction.formattedDate,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isExpense ? '-' : '+'} ${transaction.currency}${formatter.format(transaction.totalAmount)}',
                            style: TextStyle(
                              color: isExpense ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Report Import Button Widget
class ReportImportWidget extends StatelessWidget {
  const ReportImportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: yellow,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Import Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click to import transactions from a file',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, "/import");
            },
            icon: const Icon(Icons.add),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: yellow,
            ),
          ),
        ],
      ),
    );
  }
}

// Report Export Button Widget
class ReportExportWidget extends StatelessWidget {
  const ReportExportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: red,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.download, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Export Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click to export all transactions to a file',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: red,
            ),
          ),
        ],
      ),
    );
  }
}
