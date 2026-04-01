import 'report_config.dart';

class ReportTemplate {
  final String id;
  final String labelKey;
  final String descriptionKey;
  final List<ReportSection> sections;
  final AudienceMode defaultAudience;

  const ReportTemplate({
    required this.id,
    required this.labelKey,
    required this.descriptionKey,
    required this.sections,
    required this.defaultAudience,
  });

  ReportConfig toReportConfig({required DateRange dateRange}) {
    return ReportConfig(
      enabledSections: List<ReportSection>.from(sections),
      dateRange: dateRange,
      audienceMode: defaultAudience,
    );
  }

  static const ReportTemplate quickSummary = ReportTemplate(
    id: 'quick_summary',
    labelKey: 'report_template_quick_summary',
    descriptionKey: 'report_template_quick_summary_desc',
    sections: <ReportSection>[
      ReportSection.coverPage,
      ReportSection.executiveSummary,
      ReportSection.spendingBreakdown,
      ReportSection.cashFlow,
    ],
    defaultAudience: AudienceMode.personal,
  );

  static const ReportTemplate monthlyReview = ReportTemplate(
    id: 'monthly_review',
    labelKey: 'report_template_monthly_review',
    descriptionKey: 'report_template_monthly_review_desc',
    sections: <ReportSection>[
      ReportSection.coverPage,
      ReportSection.executiveSummary,
      ReportSection.spendingBreakdown,
      ReportSection.incomeAnalysis,
      ReportSection.cashFlow,
      ReportSection.topMerchants,
      ReportSection.alerts,
      ReportSection.coaching,
    ],
    defaultAudience: AudienceMode.personal,
  );

  static const ReportTemplate fullFinancialReview = ReportTemplate(
    id: 'full_financial_review',
    labelKey: 'report_template_full_review',
    descriptionKey: 'report_template_full_review_desc',
    sections: <ReportSection>[
      ReportSection.coverPage,
      ReportSection.executiveSummary,
      ReportSection.spendingBreakdown,
      ReportSection.incomeAnalysis,
      ReportSection.cashFlow,
      ReportSection.budgetActual,
      ReportSection.topMerchants,
      ReportSection.investmentPortfolio,
      ReportSection.forecast,
      ReportSection.alerts,
      ReportSection.coaching,
      ReportSection.billsRecurring,
      ReportSection.transactionLog,
    ],
    defaultAudience: AudienceMode.professional,
  );

  static const ReportTemplate taxPrep = ReportTemplate(
    id: 'tax_prep',
    labelKey: 'report_template_tax_prep',
    descriptionKey: 'report_template_tax_prep_desc',
    sections: <ReportSection>[
      ReportSection.coverPage,
      ReportSection.incomeAnalysis,
      ReportSection.spendingBreakdown,
      ReportSection.topMerchants,
      ReportSection.transactionLog,
    ],
    defaultAudience: AudienceMode.professional,
  );

  static const ReportTemplate investmentFocus = ReportTemplate(
    id: 'investment_focus',
    labelKey: 'report_template_investment_focus',
    descriptionKey: 'report_template_investment_focus_desc',
    sections: <ReportSection>[
      ReportSection.coverPage,
      ReportSection.executiveSummary,
      ReportSection.investmentPortfolio,
      ReportSection.forecast,
      ReportSection.cashFlow,
    ],
    defaultAudience: AudienceMode.professional,
  );

  static const List<ReportTemplate> all = <ReportTemplate>[
    quickSummary,
    monthlyReview,
    fullFinancialReview,
    taxPrep,
    investmentFocus,
  ];
}
