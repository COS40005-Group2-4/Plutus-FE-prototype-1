import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'glass_container.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../services/tax_calculation_service.dart';
import '../services/currency_service.dart';
import '../providers/auth_notifier.dart';
import '../services/interfaces/interfaces.dart';
import '../di/service_locator.dart';
import '../providers/settings_notifier.dart';
import '../l10n/app_localizations.dart';

class TaxEstimationWidget extends ConsumerStatefulWidget {
  const TaxEstimationWidget({super.key});

  @override
  ConsumerState<TaxEstimationWidget> createState() => _TaxEstimationWidgetState();
}

class _TaxEstimationWidgetState extends ConsumerState<TaxEstimationWidget> {
  late ITransactionService _transactionService;
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  double _annualIncome = 0;
  double _estimatedTax = 0;
  double _effectiveRate = 0;
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  StreamSubscription? _transactionSubscription;

  @override
  void initState() {
    super.initState();
    _transactionService = sl<ITransactionService>();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _transactionService.setCurrentUser(currentUserId);
    }
    
    // Listen to transaction updates
    _transactionSubscription = _transactionService.transactionStream.listen((_) {
      if (mounted) {
        _calculateTax();
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
      _calculateTax();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recalculate when currency settings change
    final settingsState = ref.read(settingsNotifierProvider);
    if (settingsState.isInitialized) {
      _calculateTax();
    }
  }
  
  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _calculateTax() async {
    setState(() => _isLoading = true);
    
    try {
      final transactions = await _transactionService.getTransactions();
      if (!mounted) return;
      final settingsState = ref.read(settingsNotifierProvider);
      final userCurrency = settingsState.currency.code;
      
      final startOfYear = DateTime(_selectedYear, 1, 1);
      final endOfYear = DateTime(_selectedYear, 12, 31, 23, 59, 59);

      double totalIncomeInVND = 0;
      
      for (final transaction in transactions) {
        final txDate = transaction.dateTime;
        
        if (txDate.isAfter(startOfYear.subtract(const Duration(days: 1))) && 
            txDate.isBefore(endOfYear.add(const Duration(days: 1)))) {
          
          bool isIncome = false;
          double incomeAmount = 0;
          String transactionCurrency = 'VND';
          
          if (transaction.postings.isNotEmpty) {
            for (final posting in transaction.postings) {
              final account = posting.account.toLowerCase();
              
              if (account.startsWith('income:')) {
                if (posting.amount < 0) {
                  isIncome = true;
                  incomeAmount = posting.amount.abs();
                  transactionCurrency = posting.commodity;
                  break;
                }
              }
              else if ((account.startsWith('assets:') || account.startsWith('asset:')) && posting.amount > 0) {
                final hasIncomePosting = transaction.postings.any((p) => 
                  p.account.toLowerCase().startsWith('income:') && p.amount < 0
                );
                if (hasIncomePosting) {
                  isIncome = true;
                  incomeAmount = posting.amount;
                  transactionCurrency = posting.commodity;
                  break;
                }
              }
            }
          }
          
          if (isIncome && incomeAmount > 0) {
            final incomeInVND = CurrencyService.toVND(incomeAmount, transactionCurrency);
            totalIncomeInVND += incomeInVND;
          }
        }
      }
      
      final taxResult = TaxCalculationService.calculateAnnualTax(
        annualIncome: totalIncomeInVND,
        numberOfDependents: 0,
      );
      
      final annualIncomeInUserCurrency = CurrencyService.fromVND(totalIncomeInVND, userCurrency);
      final taxInUserCurrency = CurrencyService.fromVND(taxResult['annualTax'] ?? 0, userCurrency);
      
      if (mounted) {
        setState(() {
          _annualIncome = annualIncomeInUserCurrency;
          _estimatedTax = taxInUserCurrency;
          _effectiveRate = taxResult['effectiveRate'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error calculating tax: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _annualIncome = 0;
          _estimatedTax = 0;
          _effectiveRate = 0;
          _isLoading = false;
        });
      }
    }
  }

  void _showYearPicker() async {
    final currentYear = DateTime.now().year;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Year',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 300,
                width: 200,
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final year = currentYear - index;
                    final isSelected = year == _selectedYear;
                    return GlassContainer(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isSelected ? AppColors.taxAccent : Colors.transparent,
                      opacity: isSelected ? 0.3 : 0,
                      borderRadius: 8,
                      child: ListTile(
                        title: Text(
                          year.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        onTap: () => Navigator.pop(context, year),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (result != null && result != _selectedYear) {
      setState(() {
        _selectedYear = result;
      });
      _calculateTax();
    }
  }

  void _showTaxDetails() {
    final settingsState = ref.read(settingsNotifierProvider);
    final userCurrency = settingsState.currency.code;
    final taxResult = TaxCalculationService.calculateAnnualTax(
      annualIncome: CurrencyService.toVND(_annualIncome, userCurrency),
      numberOfDependents: 0,
    );
    
    final monthlyTaxableIncome = taxResult['monthlyTaxableIncome']!;
    final bracket = TaxCalculationService.getTaxBracket(monthlyTaxableIncome);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 16,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).taxBreakdown,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${AppLocalizations.of(context).financialYear} $_selectedYear',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Tax Bracket Table
                _buildSectionTitle(AppLocalizations.of(context).vietnameseTaxBrackets),
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  opacity: 0.05,
                  borderRadius: 8,
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      const Divider(color: Colors.white30, height: 8),
                      _buildTableRow('0 - 5M', '5%', '0'),
                      _buildTableRow('5M - 10M', '10%', '250K'),
                      _buildTableRow('10M - 18M', '15%', '750K'),
                      _buildTableRow('18M - 32M', '20%', '1.65M'),
                      _buildTableRow('32M - 52M', '25%', '3.25M'),
                      _buildTableRow('52M - 80M', '30%', '5.85M'),
                      _buildTableRow('> 80M', '35%', '9.85M'),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Colors.white30),
                const SizedBox(height: AppSpacing.lg),
                
                // Income Section
                _buildSectionTitle(AppLocalizations.of(context).incomeSection),
                _buildDetailRow(AppLocalizations.of(context).annualIncome, taxResult['annualIncome']!),
                _buildDetailRow(AppLocalizations.of(context).monthlyIncome, taxResult['monthlyIncome']!),
                
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Colors.white30),
                const SizedBox(height: AppSpacing.lg),
                
                // Deductions Section
                _buildSectionTitle(AppLocalizations.of(context).deductionsSection),
                _buildDetailRow(AppLocalizations.of(context).personalDeduction, 11000000 * 12),
                _buildDetailRow(AppLocalizations.of(context).totalDeductions, taxResult['annualDeductions']!),
                
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Colors.white30),
                const SizedBox(height: AppSpacing.lg),
                
                // Taxable Income Section
                _buildSectionTitle(AppLocalizations.of(context).taxableIncomeSection),
                _buildDetailRow(AppLocalizations.of(context).annualTaxable, taxResult['annualTaxableIncome']!),
                _buildDetailRow(AppLocalizations.of(context).monthlyTaxable, taxResult['monthlyTaxableIncome']!),
                
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Colors.white30),
                const SizedBox(height: AppSpacing.lg),
                
                // Tax Bracket
                if (bracket != null) ...[
                  _buildSectionTitle(AppLocalizations.of(context).taxBracket),
                  GlassContainer(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    opacity: 0.1,
                    borderRadius: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations.of(context).rate}: ${((bracket['rate'] as double) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${AppLocalizations.of(context).range}: ${_currencyFormat.format(bracket['min'])} - ${bracket['max'] == double.infinity ? '∞' : _currencyFormat.format(bracket['max'])} ₫/month',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: AppSpacing.lg),
                ],
                
                // Tax Calculation
                _buildSectionTitle(AppLocalizations.of(context).taxCalculation),
                _buildDetailRow(AppLocalizations.of(context).monthlyTax, taxResult['monthlyTax']!, highlight: true),
                _buildDetailRow(AppLocalizations.of(context).annualTax, taxResult['annualTax']!, highlight: true),
                _buildDetailRow(AppLocalizations.of(context).effectiveRate, _effectiveRate, isPercentage: true),
                
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: Colors.white30),
                const SizedBox(height: AppSpacing.lg),
                
                // Net Income
                _buildSectionTitle(AppLocalizations.of(context).netIncomeSection),
                _buildDetailRow(AppLocalizations.of(context).afterTax, taxResult['netIncome']!, highlight: true),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).basedOnVietnameseTaxLaw,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            AppLocalizations.of(context).monthlyIncomeRange,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            AppLocalizations.of(context).rate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            AppLocalizations.of(context).deduction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String range, String rate, String deduction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              range,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              rate,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              deduction,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double value, {bool highlight = false, bool isPercentage = false}) {
    final settingsState = ref.read(settingsNotifierProvider);
    final currencySymbol = settingsState.currency.symbol;
    final userCurrency = settingsState.currency.code;
    
    // Convert VND values to user currency for display
    final displayValue = isPercentage ? value : CurrencyService.fromVND(value, userCurrency);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white70,
              fontSize: highlight ? 14 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isPercentage 
                ? '${displayValue.toStringAsFixed(2)}%'
                : '${_currencyFormat.format(displayValue)} $currencySymbol',
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white70,
              fontSize: highlight ? 14 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsNotifierProvider);
    final currencySymbol = settingsState.currency.symbol;
    
    return GlassContainer(
      color: AppColors.taxAccent,
      opacity: 0.2,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.account_balance, size: 32, color: Colors.white),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onPressed: _calculateTax,
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context).taxEstimation,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: AppLocalizations.of(context).widgetHelpTaxEstimation,
                  child: Icon(
                    Icons.help_outline,
                    size: 14,
                    color: AppColors.textTertiary(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(context).vietnamesePersonalIncomeTax,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Year Selector
            GestureDetector(
              onTap: _showYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'FY $_selectedYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else ...[
              // Income vs Tax Bar
              if (_annualIncome > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 24,
                        child: ClipRRect(
                          borderRadius: AppRadius.borderSm,
                          child: Row(
                            children: [
                              Expanded(
                                flex: ((_annualIncome - _estimatedTax) * 100 / _annualIncome).round().clamp(1, 99),
                                child: Container(color: AppColors.positive(Theme.of(context).brightness).withValues(alpha:0.7)),
                              ),
                              if (_estimatedTax > 0)
                                Expanded(
                                  flex: (_estimatedTax * 100 / _annualIncome).round().clamp(1, 99),
                                  child: Container(color: AppColors.negative(Theme.of(context).brightness).withValues(alpha:0.7)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.positive(Theme.of(context).brightness).withValues(alpha:0.7), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: AppSpacing.xs),
                              const Text('Net', style: TextStyle(color: Colors.white54, fontSize: 9)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.negative(Theme.of(context).brightness).withValues(alpha:0.7), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: AppSpacing.xs),
                              const Text('Tax', style: TextStyle(color: Colors.white54, fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Tax Amount Display
              GlassContainer(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                opacity: 0.1,
                borderRadius: 8,
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context).estimatedTaxLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_currencyFormat.format(_estimatedTax)} $currencySymbol',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${AppLocalizations.of(context).rate}: ${_effectiveRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Income Summary
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Column(
                  children: [
                    _buildInfoRow(AppLocalizations.of(context).annualIncome, _annualIncome),
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(AppLocalizations.of(context).netIncomeSection, _annualIncome - _estimatedTax),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Details Button
              TextButton.icon(
                onPressed: _showTaxDetails,
                icon: const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                label: Text(
                  AppLocalizations.of(context).clickForDetails,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, double value) {
    final settingsState = ref.read(settingsNotifierProvider);
    final currencySymbol = settingsState.currency.symbol;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        Text(
          '${_currencyFormat.format(value)} $currencySymbol',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
