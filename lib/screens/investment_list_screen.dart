import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/investment_model.dart';
import '../services/interfaces/i_investment_service.dart';
import '../di/service_locator.dart';
import '../providers/auth_notifier.dart';
import '../widgets/glass_container.dart';
import '../widgets/add_investment_dialog.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$assetName added to your portfolio'),
                  backgroundColor: AppColors.success,
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
                  content: const Text("Couldn't add investment. Please try again."),
                  backgroundColor: AppColors.error,
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
    final brightness = Theme.of(context).brightness;
    final brand = AppColors.brand(brightness);

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
            TabBar(
              tabs: [
                Tab(text: localizations.investmentTabActive),
                Tab(text: localizations.investmentTabClosed),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildContent(localizations, brightness, closed: false),
                  _buildContent(localizations, brightness, closed: true),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: brand,
        foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildContent(AppLocalizations localizations, Brightness brightness, {required bool closed}) {
    final brand = AppColors.brand(brightness);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: brand),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                localizations.errorLoadingData,
                style: AppTextStyles.subtitleStyle.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTextStyles.bodyStyle.copyWith(
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 36,
                  color: brand,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                closed
                    ? localizations.investmentNoClosed
                    : localizations.noInvestmentsYet,
                style: AppTextStyles.subtitleStyle.copyWith(
                  color: AppColors.textSecondary(brightness),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
          return _buildInvestmentCard(filtered[index], brightness);
        },
      ),
    );
  }

  Widget _buildInvestmentCard(InvestmentModel investment, Brightness brightness) {
    final isPositive = investment.isPositiveReturn();
    final changeColor = isPositive
        ? AppColors.positive(brightness)
        : AppColors.negative(brightness);
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);
    final brand = AppColors.brand(brightness);

    return GlassContainer(
      borderRadius: AppRadius.lg,
      child: InkWell(
        borderRadius: AppRadius.borderLg,
        onTap: () async {
          await context.push('/dashboard/investments/${investment.id}');
          if (mounted) await _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.10),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  size: 22,
                  color: brand,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.assetName,
                      style: AppTextStyles.bodyStrongStyle.copyWith(
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${investment.assetType.name.toUpperCase()} · ${investment.quantity} units',
                      style: AppTextStyles.captionStyle.copyWith(
                        color: textSecondary,
                      ),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.merge(AppTextStyles.numericStyle)
                        .copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        investment.getFormattedGainLoss(),
                        style: AppTextStyles.labelMediumStyle.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
