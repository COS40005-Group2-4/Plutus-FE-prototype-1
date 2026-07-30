import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/report_config.dart';
import '../models/report_template.dart';
import '../providers/auth_notifier.dart';
import '../providers/report_notifier.dart';
import '../providers/settings_notifier.dart';
import '../router/app_router.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import '../widgets/core/app_card.dart';

class ReportConfigScreen extends ConsumerStatefulWidget {
  const ReportConfigScreen({super.key});

  @override
  ConsumerState<ReportConfigScreen> createState() => _ReportConfigScreenState();
}

class _ReportConfigScreenState extends ConsumerState<ReportConfigScreen> {
  ReportTemplate _selectedTemplate = ReportTemplate.quickSummary;
  DateRangePreset _selectedPreset = DateRangePreset.thisMonth;
  late Set<ReportSection> _enabledSections;
  AudienceMode _audienceMode = AudienceMode.personal;
  bool _aiEnabled = true;
  String _reportLocale = 'en';

  @override
  void initState() {
    super.initState();
    _enabledSections = Set<ReportSection>.from(_selectedTemplate.sections);
    final SettingsState settings = ref.read(settingsNotifierProvider);
    _reportLocale = settings.language.code;
  }

  void _applyTemplate(ReportTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _enabledSections = Set<ReportSection>.from(template.sections);
      _audienceMode = template.defaultAudience;
    });
  }

  DateRange _buildDateRange() {
    if (_selectedPreset == DateRangePreset.custom) {
      final DateTime now = DateTime.now();
      return DateRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
        comparisonStart: DateTime(now.year, now.month - 1, 1),
        comparisonEnd: DateTime(now.year, now.month - 1, now.day),
      );
    }
    return _selectedPreset.calculate(DateTime.now());
  }

  Future<void> _generate(BuildContext context) async {
    final reportNotifier = ref.read(reportNotifierProvider.notifier);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    final DateRange dateRange = _buildDateRange();
    final ReportConfig config = ReportConfig(
      enabledSections: _enabledSections.toList(),
      dateRange: dateRange,
      audienceMode: _audienceMode,
      aiEnabled: _aiEnabled,
      reportLocale: _reportLocale,
    );

    reportNotifier.updateConfig(config);

    await reportNotifier.generateReport(
      userId: authNotifier.currentUserId,
    );

    if (context.mounted) {
      context.push(AppRoutes.reportPreview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('report_config_title')),
      ),
      body: Consumer(
        builder: (BuildContext ctx, WidgetRef innerRef, Widget? _) {
          final ReportState reportState = innerRef.watch(reportNotifierProvider);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildSectionHeader(l10n.translate('report_section_template'), t),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTemplatePicker(t, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_section_date_range'), t),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDateRangeChips(t, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_section_sections'), t),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSectionToggles(t, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_section_audience'), t),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAudienceSegment(l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_language'), t),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLanguagePicker(l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAiToggle(t, l10n),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildGenerateButton(context, reportState, l10n),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
              if (reportState.isGenerating)
                _buildLoadingOverlay(t, reportState, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, PlutusTokens t) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: t.text,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTemplatePicker(PlutusTokens t, AppLocalizations l10n) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ReportTemplate.all.map((ReportTemplate template) {
        final bool isSelected = _selectedTemplate.id == template.id;
        return GestureDetector(
          onTap: () => _applyTemplate(template),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? t.goldSelectedFill : t.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isSelected ? Border.all(color: t.gold) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _templateIcon(template.id),
                      size: 16,
                      color: isSelected ? t.goldText : t.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _templateLabel(template.id, l10n),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? t.goldText : t.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _templateIcon(String id) {
    switch (id) {
      case 'quick_summary':
        return Icons.flash_on_outlined;
      case 'monthly_review':
        return Icons.calendar_month_outlined;
      case 'full_financial_review':
        return Icons.account_balance_outlined;
      case 'tax_prep':
        return Icons.receipt_long_outlined;
      case 'investment_focus':
        return Icons.trending_up_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _templateLabel(String id, AppLocalizations l10n) {
    switch (id) {
      case 'quick_summary':
        return l10n.translate('report_tpl_quick');
      case 'monthly_review':
        return l10n.translate('report_tpl_monthly');
      case 'full_financial_review':
        return l10n.translate('report_tpl_full');
      case 'tax_prep':
        return l10n.translate('report_tpl_tax');
      case 'investment_focus':
        return l10n.translate('report_tpl_investments');
      default:
        return id;
    }
  }

  Widget _buildDateRangeChips(PlutusTokens t, AppLocalizations l10n) {
    const List<DateRangePreset> presets = <DateRangePreset>[
      DateRangePreset.thisMonth,
      DateRangePreset.lastQuarter,
      DateRangePreset.yearToDate,
      DateRangePreset.last12Months,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: presets.map((DateRangePreset preset) {
        final bool isSelected = _selectedPreset == preset;
        return ChoiceChip(
          label: Text(_presetLabel(preset, l10n)),
          selected: isSelected,
          onSelected: (bool selected) {
            if (selected) {
              setState(() => _selectedPreset = preset);
            }
          },
          selectedColor: t.goldSelectedFill,
          backgroundColor: t.surfaceSubtle,
          labelStyle: TextStyle(
            color: isSelected ? t.goldText : t.textSecondary,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: BorderSide(
              color: isSelected ? t.gold : t.border,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _presetLabel(DateRangePreset preset, AppLocalizations l10n) {
    switch (preset) {
      case DateRangePreset.thisMonth:
        return l10n.translate('report_preset_this_month');
      case DateRangePreset.lastQuarter:
        return l10n.translate('report_preset_last_quarter');
      case DateRangePreset.yearToDate:
        return l10n.translate('report_preset_ytd');
      case DateRangePreset.last12Months:
        return l10n.translate('report_preset_last_12m');
      case DateRangePreset.custom:
        return l10n.translate('report_preset_custom');
    }
  }

  Widget _buildSectionToggles(PlutusTokens t, AppLocalizations l10n) {
    final List<(ReportSection, String, IconData)> sectionMeta =
        <(ReportSection, String, IconData)>[
      (ReportSection.coverPage, l10n.translate('report_sec_cover'), Icons.bookmark_outline),
      (ReportSection.executiveSummary, l10n.translate('report_sec_summary'), Icons.summarize_outlined),
      (ReportSection.spendingBreakdown, l10n.translate('report_sec_spending'), Icons.pie_chart_outline),
      (ReportSection.incomeAnalysis, l10n.translate('report_sec_income'), Icons.trending_up_outlined),
      (ReportSection.cashFlow, l10n.translate('report_sec_cashflow'), Icons.waterfall_chart_outlined),
      (ReportSection.budgetActual, l10n.translate('report_sec_budget'), Icons.bar_chart_outlined),
      (ReportSection.topMerchants, l10n.translate('report_sec_merchants'), Icons.store_outlined),
      (ReportSection.investmentPortfolio, l10n.translate('report_sec_investments'), Icons.candlestick_chart_outlined),
      (ReportSection.forecast, l10n.translate('report_sec_forecast'), Icons.auto_graph_outlined),
      (ReportSection.alerts, l10n.translate('report_sec_alerts'), Icons.notifications_outlined),
      (ReportSection.coaching, l10n.translate('report_sec_coaching'), Icons.lightbulb_outline),
      (ReportSection.billsRecurring, l10n.translate('report_sec_bills'), Icons.repeat_outlined),
      (ReportSection.transactionLog, l10n.translate('report_sec_transactions'), Icons.list_alt_outlined),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: sectionMeta.asMap().entries.map((MapEntry<int, (ReportSection, String, IconData)> entry) {
          final int idx = entry.key;
          final (ReportSection section, String label, IconData icon) = entry.value;
          final bool isEnabled = _enabledSections.contains(section);

          return Column(
            children: [
              SwitchListTile(
                dense: true,
                secondary: Icon(icon, size: 20, color: isEnabled ? t.goldText : t.textSecondary),
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isEnabled ? t.goldText : t.textSecondary,
                  ),
                ),
                value: isEnabled,
                onChanged: (bool value) {
                  setState(() {
                    if (value) {
                      _enabledSections.add(section);
                    } else {
                      _enabledSections.remove(section);
                    }
                  });
                },
              ),
              if (idx < sectionMeta.length - 1)
                Divider(
                  height: 1,
                  color: t.border,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAudienceSegment(AppLocalizations l10n) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SegmentedButton<AudienceMode>(
        segments: <ButtonSegment<AudienceMode>>[
          ButtonSegment<AudienceMode>(
            value: AudienceMode.personal,
            label: Text(l10n.translate('report_audience_personal')),
            icon: const Icon(Icons.person_outline, size: 18),
          ),
          ButtonSegment<AudienceMode>(
            value: AudienceMode.professional,
            label: Text(l10n.translate('report_audience_professional')),
            icon: const Icon(Icons.business_center_outlined, size: 18),
          ),
        ],
        selected: <AudienceMode>{_audienceMode},
        onSelectionChanged: (Set<AudienceMode> selection) {
          if (selection.isNotEmpty) {
            setState(() => _audienceMode = selection.first);
          }
        },
      ),
    );
  }

  Widget _buildLanguagePicker(AppLocalizations l10n) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SegmentedButton<String>(
        segments: <ButtonSegment<String>>[
          ButtonSegment<String>(
            value: 'en',
            label: Text(l10n.translate('language_english')),
          ),
          ButtonSegment<String>(
            value: 'vi',
            label: Text(l10n.translate('language_vietnamese')),
          ),
        ],
        selected: <String>{_reportLocale},
        onSelectionChanged: (Set<String> selection) {
          if (selection.isNotEmpty) {
            setState(() => _reportLocale = selection.first);
          }
        },
      ),
    );
  }

  Widget _buildAiToggle(PlutusTokens t, AppLocalizations l10n) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          Icons.auto_awesome_outlined,
          size: 20,
          color: _aiEnabled ? t.gold : t.textSecondary,
        ),
        title: Text(
          l10n.translate('report_ai_title'),
          style: TextStyle(fontSize: 14, color: t.text),
        ),
        subtitle: Text(
          l10n.translate('report_ai_subtitle'),
          style: TextStyle(fontSize: 12, color: t.textSecondary),
        ),
        value: _aiEnabled,
        onChanged: (bool value) {
          setState(() => _aiEnabled = value);
        },
      ),
    );
  }

  Widget _buildGenerateButton(
    BuildContext context,
    ReportState reportState,
    AppLocalizations l10n,
  ) {
    final bool hasAnySections = _enabledSections.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: (reportState.isGenerating || !hasAnySections)
            ? null
            : () => _generate(context),
        icon: const Icon(Icons.auto_awesome),
        label: Text(l10n.translate('report_generate')),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(PlutusTokens t, ReportState reportState, AppLocalizations l10n) {
    return Positioned.fill(
      child: Container(
        // Brightness-independent scrim (matches Flutter's own ModalBarrier
        // convention) rather than a themed token — a light-theme t.bg tint
        // would barely dim the content behind it.
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: t.gold,
                  strokeWidth: 3,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('report_generating_loading'),
                  style: TextStyle(
                    fontSize: 14,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    value: reportState.progress,
                    color: t.gold,
                    backgroundColor: t.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
