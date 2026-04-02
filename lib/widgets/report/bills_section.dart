import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class BillsSection extends StatelessWidget {
  final ReportDataModel data;

  const BillsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
          _buildSummaryBar(),
        if (bills == null || bills.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                'No recurring bills data available',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ...bills.map((BillData bill) => _buildBillRow(bill)),
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.billsAccent,
          ),
      ],
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.billsAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: AppColors.billsAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'MONTHLY RECURRING',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.totalRecurring.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            '${data.activeBillCount} active',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(BillData bill) {
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${bill.category} • ${bill.frequency}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (change != null)
                  Text(
                    '${changeUp ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: changeUp
                          ? AppColors.expenseAccent
                          : AppColors.incomeAccent,
                    ),
                  ),
              ],
            ),
          ),
          if (bill.nextDue != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            Text(
              dateFmt.format(bill.nextDue!),
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ],
      ),
    );
  }
}
