import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_data.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_spacing.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';

class TransactionLogSection extends StatelessWidget {
  final ReportDataModel data;

  const TransactionLogSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Transaction>? transactions = data.transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_transactions'),
          icon: Icons.receipt_long_outlined,
        ),
        if (transactions == null || transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                l10n.translate('report_no_transactions'),
                style: TextStyle(color: doc.textMuted, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          _buildHeaderRow(l10n, doc),
          Divider(height: 1, color: doc.border),
          ...transactions.map((Transaction t) => _buildTransactionRow(t, doc)),
        ],
      ],
    );
  }

  Widget _buildHeaderRow(AppLocalizations l10n, PlutusTokens doc) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              l10n.translate('report_col_date'),
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.translate('report_col_payee'),
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.translate('report_col_account'),
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.translate('report_col_amount'),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction t, PlutusTokens doc) {
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
          bottom: BorderSide(color: doc.border),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              dateFmt.format(t.dateTime),
              style: TextStyle(fontSize: 12, color: doc.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              t.payee.isNotEmpty ? t.payee : t.description,
              style: TextStyle(fontSize: 12, color: doc.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              account,
              style: TextStyle(fontSize: 11, color: doc.textMuted),
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
                    ? doc.success.text
                    : doc.error.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
