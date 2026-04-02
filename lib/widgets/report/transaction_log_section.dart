import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_data.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'report_section_header.dart';

class TransactionLogSection extends StatelessWidget {
  final ReportDataModel data;

  const TransactionLogSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<Transaction>? transactions = data.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ReportSectionHeader(
          title: 'Transaction Log',
          icon: Icons.receipt_long_outlined,
        ),
        if (transactions == null || transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                'No transactions available',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          _buildHeaderRow(),
          const Divider(height: 1, color: Colors.white12),
          ...transactions.map((Transaction t) => _buildTransactionRow(t)),
        ],
      ],
    );
  }

  Widget _buildHeaderRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              'DATE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'PAYEE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'AMOUNT',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction t) {
    final double amount =
        t.postings.isNotEmpty ? t.postings.first.amount : 0;
    final bool isPositive = amount >= 0;
    final String account =
        t.postings.isNotEmpty ? t.postings.first.account : '-';
    final String commodity =
        t.postings.isNotEmpty ? t.postings.first.commodity : '';
    final DateFormat dateFmt = DateFormat('MM/dd');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              dateFmt.format(t.dateTime),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              t.payee.isNotEmpty ? t.payee : t.description,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              account,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isPositive ? '+' : ''}${amount.toStringAsFixed(2)} $commodity',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPositive
                    ? AppColors.incomeAccent
                    : AppColors.expenseAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
