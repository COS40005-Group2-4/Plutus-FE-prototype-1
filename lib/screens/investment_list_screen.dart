import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/investment_model.dart';
import '../services/interfaces/i_investment_service.dart';
import '../di/service_locator.dart';
import '../providers/auth_notifier.dart';
import '../widgets/core/app_card.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/metric_delta.dart';
import '../widgets/add_investment_dialog.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';

/// Full screen view of all investments
class InvestmentListScreen extends ConsumerStatefulWidget {
  const InvestmentListScreen({super.key});

  @override
  ConsumerState<InvestmentListScreen> createState() => _InvestmentListScreenState();
}

class _InvestmentListScreenState extends ConsumerState<InvestmentListScreen> {
  final IInvestmentService _service = sl<IInvestmentService>();
  List<InvestmentModel>? _investments;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authNotifier = ref.read(authNotifierProvider.notifier);
    if (authNotifier.currentUserId != null) {
      _service.setUserId(authNotifier.currentUserId!);
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final investments = await _service.getInvestmentList(forceRefresh: true);
      if (mounted) {
        setState(() {
          _investments = investments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showAddDialog() {
    final PlutusTokens t = context.tokens;

    showDialog(
      context: context,
      builder: (context) => AddInvestmentDialog(
        onSave: (assetType, assetName, quantity, purchaseValue, currency, purchaseDate) async {
          try {
            setState(() {
              _isLoading = true;
              _error = null;
            });

            final investment = InvestmentModel(
              id: '',
              assetType: assetType,
              assetName: assetName,
              quantity: quantity,
              purchaseValue: purchaseValue,
              currency: currency,
              purchaseDate: purchaseDate,
            );

            final service = sl<IInvestmentService>();
            final authNotifier = ref.read(authNotifierProvider.notifier);
            if (authNotifier.currentUserId != null) {
              service.setUserId(authNotifier.currentUserId!);
            }
            await service.saveInvestment(investment);

            if (context.mounted) {
              final localizations = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$assetName ${localizations.investmentAdded}'),
                  backgroundColor: t.success.dot,
                ),
              );
              await _loadData();
            }
          } catch (e) {
            if (context.mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).investmentAddFailed),
                  backgroundColor: t.error.dot,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.investments),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            if (_investments != null && _error == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _buildPortfolioTotal(localizations, t),
              ),
            TabBar(
              tabs: [
                Tab(text: localizations.investmentTabActive),
                Tab(text: localizations.investmentTabClosed),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildContent(localizations, t, closed: false),
                  _buildContent(localizations, t, closed: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text(localizations.add),
      ),
    );
  }

  /// The gold moment of this screen (spec §7 + §3.4): current portfolio
  /// value across active holdings, via the existing
  /// [IInvestmentService.getTotalPortfolioValue] — no new computation.
  Widget _buildPortfolioTotal(AppLocalizations localizations, PlutusTokens t) {
    final activeInvestments =
        (_investments ?? const <InvestmentModel>[]).where((i) => !i.isClosed).toList();
    final total = _service.getTotalPortfolioValue(activeInvestments);
    final symbol =
        activeInvestments.isNotEmpty ? activeInvestments.first.getCurrencySymbol() : '\$';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.portfolioTotal,
          style: AppTextStyles.overlineStyle.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '$symbol${total.toStringAsFixed(2)}',
          style: AppTextStyles.numericStyle.copyWith(color: t.goldText, fontSize: 24),
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations localizations, PlutusTokens t, {required bool closed}) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: t.brandNavy),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: t.error.text),
              const SizedBox(height: AppSpacing.lg),
              Text(
                localizations.errorLoadingData,
                style: AppTextStyles.subtitleStyle.copyWith(color: t.error.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTextStyles.bodyStyle.copyWith(color: t.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _loadData,
                child: Text(localizations.retry),
              ),
            ],
          ),
        ),
      );
    }

    final all = _investments ?? const <InvestmentModel>[];
    final filtered = all.where((i) => i.isClosed == closed).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.savings_outlined,
        title: closed ? localizations.investmentNoClosed : localizations.noInvestmentsYet,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl * 2,
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          return _buildInvestmentCard(filtered[index], t);
        },
      ),
    );
  }

  Widget _buildInvestmentCard(InvestmentModel investment, PlutusTokens t) {
    return AppCard(
      onTap: () async {
        await context.push('/dashboard/investments/${investment.id}');
        if (mounted) await _loadData();
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.brandNavy.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(
              Icons.show_chart_rounded,
              size: 22,
              color: t.brandNavy,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.assetName,
                  style: AppTextStyles.bodyStrongStyle.copyWith(color: t.text),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${investment.assetType.name.toUpperCase()} · ${investment.quantity} units',
                  style: AppTextStyles.captionStyle.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${investment.getCurrencySymbol()}${investment.getCurrentValue().toStringAsFixed(2)}',
                style: AppTextStyles.numericStyle.copyWith(fontSize: 18, color: t.text),
              ),
              const SizedBox(height: 2),
              MetricDelta(percent: investment.getGainLossPercent(), decimals: 2),
            ],
          ),
        ],
      ),
    );
  }
}
