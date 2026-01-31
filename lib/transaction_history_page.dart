import 'package:flutter/material.dart';
import 'transaction_service.dart';
import 'widgets/glass_container.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => TransactionHistoryPageState();
}

class TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionService _service = TransactionService();
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void refresh() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    final transactions = await _service.getTransactions();
    setState(() {
      _transactions = transactions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions found'))
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GlassContainer(
                          borderRadius: 12,
                          opacity: 0.2,
                          child: ListTile(
                            title: Text(transaction['account'] ?? 'Unknown'),
                            subtitle: Text(
                              '${transaction['type'] ?? 'unknown'} - ${transaction['currency'] ?? ''} ${transaction['amount'] ?? ''}',
                            ),
                            trailing: Text(
                              DateTime.parse(transaction['date'] ?? DateTime.now().toIso8601String())
                                  .toString()
                                  .split(' ')[0],
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

