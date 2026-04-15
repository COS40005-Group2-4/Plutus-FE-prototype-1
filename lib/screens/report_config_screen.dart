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
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/glass_container.dart';

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
    final Brightness brightness = Theme.of(context).brightness;
    final Color textPrimary = AppColors.textPrimary(brightness);
    final Color textSecondary = AppColors.textSecondary(brightness);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('report_config_title'),
          style: TextStyle(color: textPrimary),
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      body: Consumer(
        builder: (BuildContext ctx, WidgetRef innerRef, Widget? _) {
          final ReportState reportState = innerRef.watch(reportNotifierProvider);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _buildSectionHeader(l10n.translate('report_section_template'), textPrimary),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTemplatePicker(brightness, textPrimary, textSecondary, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_section_date_range'), textPrimary),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDateRangeChips(brightness, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_section_sections'), textPrimary),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSectionToggles(brightness, textPrimary, textSecondary, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_section_audience'), textPrimary),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAudienceSegment(brightness, textPrimary, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionHeader(l10n.translate('report_language'), textPrimary),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLanguagePicker(brightness, textPrimary, l10n),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAiToggle(brightness, textPrimary, textSecondary, l10n),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildGenerateButton(context, reportState, l10n),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
              if (reportState.isGenerating)
                _buildLoadingOverlay(brightness, reportState, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTemplatePicker(
    Brightness brightness,
    Color textPrimary,
    Color textSecondary,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ReportTemplate.all.map((ReportTemplate template) {
        final bool isSelected = _selectedTemplate.id == template.id;
        return GestureDetector(
          onTap: () => _applyTemplate(template),
          child: GlassContainer(
            borderRadius: AppRadius.md,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: isSelected ? AppColors.primary : null,
            opacity: isSelected ? 0.3 : 0.05,
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
                      color: isSelected ? AppColors.primary : textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _templateLabel(template.id, l10n),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : textPrimary,
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

  Widget _buildDateRangeChips(Brightness brightness, AppLocalizations l10n) {
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
        return ChoiceChip(
          label: Text(_presetLabel(preset, l10n)),
          selected: _selectedPreset == preset,
          onSelected: (bool selected) {
            if (selected) {
              setState(() => _selectedPreset = preset);
            }
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.25),
          backgroundColor: brightness == Brightness.dark
              ? AppColors.surfaceDark.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.5),
          labelStyle: TextStyle(
            color: _selectedPreset == preset
                ? AppColors.primary
                : AppColors.textSecondary(brightness),
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: BorderSide(
              color: _selectedPreset == preset
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.borderLine(brightness),
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

  Widget _buildSectionToggles(
    Brightness brightness,
    Color textPrimary,
    Color textSecondary,
    AppLocalizations l10n,
  ) {
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

    return GlassContainer(
      borderRadius: AppRadius.lg,
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
                secondary: Icon(icon, size: 20, color: isEnabled ? AppColors.primary : textSecondary),
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isEnabled ? textPrimary : textSecondary,
                  ),
                ),
                value: isEnabled,
                activeThumbColor: AppColors.primary,
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
                  color: AppColors.borderLine(brightness),
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAudienceSegment(Brightness brightness, Color textPrimary, AppLocalizations l10n) {
    return GlassContainer(
      borderRadius: AppRadius.lg,
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
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary.withValues(alpha: 0.25);
              }
              return Colors.transparent;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return AppColors.textSecondary(brightness);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLanguagePicker(Brightness brightness, Color textPrimary, AppLocalizations l10n) {
    return GlassContainer(
      borderRadius: AppRadius.lg,
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
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary.withValues(alpha: 0.25);
              }
              return Colors.transparent;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return AppColors.textSecondary(brightness);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAiToggle(
    Brightness brightness,
    Color textPrimary,
    Color textSecondary,
    AppLocalizations l10n,
  ) {
    return GlassContainer(
      borderRadius: AppRadius.lg,
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          Icons.auto_awesome_outlined,
          size: 20,
          color: _aiEnabled ? AppColors.primary : textSecondary,
        ),
        title: Text(
          l10n.translate('report_ai_title'),
          style: TextStyle(fontSize: 14, color: textPrimary),
        ),
        subtitle: Text(
          l10n.translate('report_ai_subtitle'),
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
        value: _aiEnabled,
        activeThumbColor: AppColors.primary,
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
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
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

  Widget _buildLoadingOverlay(Brightness brightness, ReportState reportState, AppLocalizations l10n) {
    return Positioned.fill(
      child: Container(
        color: brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.7),
        child: Center(
          child: GlassContainer(
            borderRadius: AppRadius.xl,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('report_generating_loading'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: 180,
                  child: LinearProgressIndicator(
                    value: reportState.progress,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
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
