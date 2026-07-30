import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class BillsSection extends StatelessWidget {
  final ReportDataModel data;

  const BillsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<BillData>? bills = data.bills;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.billsRecurring];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ReportSectionHeader(
          title: 'Bills & Recurring',
          icon: Icons.repeat_rounded,
        ),
        if (bills != null && bills.isNotEmpty)
          _buildSummaryBar(l10n, doc),
        if (bills == null || bills.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                l10n.noRecurringBills,
                style: TextStyle(color: doc.textMuted, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ...bills.map((BillData bill) => _buildBillRow(bill, doc)),
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
          ),
      ],
    );
  }

  Widget _buildSummaryBar(AppLocalizations l10n, PlutusTokens doc) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: doc.info.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: doc.info.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.monthlyRecurring.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: doc.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.totalRecurring.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: doc.text,
                ),
              ),
            ],
          ),
          Text(
            '${data.activeBillCount} active',
            style: TextStyle(
              fontSize: 14,
              color: doc.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(BillData bill, PlutusTokens doc) {
    final double? change = bill.changePercent;
    final bool changeUp = (change ?? 0) > 0;
    final DateFormat dateFmt = DateFormat('MMM d');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: doc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: doc.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  bill.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: doc.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${bill.category} • ${bill.frequency}',
                  style: TextStyle(fontSize: 11, color: doc.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  bill.amount.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    color: doc.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (change != null)
                  Text(
                    '${changeUp ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: changeUp
                          ? doc.error.text
                          : doc.success.text,
                    ),
                  ),
              ],
            ),
          ),
          if (bill.nextDue != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            Text(
              dateFmt.format(bill.nextDue!),
              style: TextStyle(fontSize: 11, color: doc.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
