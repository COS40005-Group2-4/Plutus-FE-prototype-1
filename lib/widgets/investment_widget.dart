import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/investment_model.dart';
import '../services/investment_service.dart';
import 'glass_container.dart';
import 'add_investment_dialog.dart';
import '../l10n/app_localizations.dart';

/// Investment Dashboard Widget
/// 
/// Displays portfolio summary with line chart showing price history
class InvestmentWidget extends StatefulWidget {
  const InvestmentWidget({super.key});

  @override
  State<InvestmentWidget> createState() => _InvestmentWidgetState();
}

class _InvestmentWidgetState extends State<InvestmentWidget> {
  final InvestmentService _service = InvestmentService();
  List<InvestmentModel>? _investments;
  bool _isLoading = false;
  String? _error;
  Map<String, String>? _roiIrrData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRoiIrr();
  }

  Future<void> _loadRoiIrr() async {
    try {
      final data = await _service.getRoiIrrData();
      if (mounted) {
        setState(() {
          _roiIrrData = data;
        });
      }
    } catch (e) {
      print('Failed to load ROI/IRR: $e');
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading investment data...');
      final investments = await _service.getInvestmentList(forceRefresh: forceRefresh);
      print('Loaded ${investments.length} investments');
      
      // Refresh price data for crypto/stock investments if forcing refresh
      if (forceRefresh && investments.isNotEmpty) {
        print('Refreshing price data for investments...');
        final updatedInvestments = <InvestmentModel>[];
        
        for (final investment in investments) {
          if (investment.assetType == AssetType.crypto || 
              investment.assetType == AssetType.stock) {
            final updated = await _service.refreshPriceData(investment);
            updatedInvestments.add(updated);
          } else {
            updatedInvestments.add(investment);
          }
        }
        
        if (mounted) {
          setState(() {
            _investments = updatedInvestments;
            _isLoading = false;
          });
        }
        
        // Also refresh ROI/IRR
        _loadRoiIrr();
      } else {
        if (mounted) {
          setState(() {
            _investments = investments;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading investments: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showInvestmentListDialog(),
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        borderRadius: 16,
        blur: 10.0,
        borderOpacity: isDark ? 0.3 : 0.2,
        opacity: isDark ? 0.3 : 0.1,
        color: isDark ? const Color(0xFF1A3A4A) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContent(localizations, isDark),
        ),
      ),
    );
  }

  void _showInvestmentListDialog() {
    showDialog(
      context: context,
      builder: (context) => _InvestmentListDialog(
        investments: _investments ?? [],
        onRefresh: () => _loadData(forceRefresh: true),
        onAdd: _showAddDialog,
      ),
    );
  }

  Widget _buildContent(AppLocalizations localizations, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return _buildError(localizations);
    }

    if (_investments == null || _investments!.isEmpty) {
      return _buildEmptyState(localizations, isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(localizations, isDark),
        const SizedBox(height: 12),
        
        // Show first investment details directly
        if (_investments!.isNotEmpty)
          _buildCompactInvestmentCard(_investments!.first, isDark),
        
        // Show count if there are more investments
        if (_investments!.length > 1) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+${_investments!.length - 1} more investment${_investments!.length - 1 > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactInvestmentCard(InvestmentModel investment, bool isDark) {
    final color = investment.isPositiveReturn()
        ? (isDark ? const Color(0xFF5DADE2) : const Color(0xFF4A90E2))
        : (isDark ? Colors.redAccent : Colors.red);

    final currentValue = investment.getCurrentValue();
    final gainLoss = investment.getGainLoss();
    final gainLossPercent = investment.getGainLossPercent();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Asset name and type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      investment.assetName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      investment.assetType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        investment.isPositiveReturn() ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${gainLossPercent >= 0 ? '+' : ''}${gainLossPercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Investment details in compact grid
          Row(
            children: [
              Expanded(
                child: _buildCompactDetail(
                  'Quantity',
                  '${investment.quantity}',
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDetail(
                  'Purchase',
                  '${investment.getCurrencySymbol()}${investment.purchaseValue.toStringAsFixed(0)}',
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactDetail(
                  'Current',
                  '${investment.getCurrencySymbol()}${currentValue.toStringAsFixed(0)}',
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDetail(
                  'Gain/Loss',
                  '${gainLoss >= 0 ? '+' : ''}${investment.getCurrencySymbol()}${gainLoss.abs().toStringAsFixed(0)}',
                  isDark,
                  valueColor: color,
                ),
              ),
            ],
          ),
          
          // ROI/IRR if available
          if (_roiIrrData != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCompactDetail(
                    'ROI',
                    _roiIrrData!['roi'] ?? '0%',
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactDetail(
                    'IRR',
                    _roiIrrData!['irr'] ?? '0%',
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactDetail(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations localizations, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localizations.investments,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddDialog(),
              color: isDark ? Colors.white70 : Colors.black54,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Add Investment',
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadData,
              color: isDark ? Colors.white70 : Colors.black54,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddInvestmentDialog(
        onSave: (assetType, assetName, quantity, purchaseValue, currency, purchaseDate) async {
          try {
            print('Widget: Saving new investment $assetName');
            
            // Create investment model
            final investment = InvestmentModel(
              id: '', // Will be generated by backend
              assetType: assetType,
              assetName: assetName,
              quantity: quantity,
              purchaseValue: purchaseValue,
              currency: currency,
              purchaseDate: purchaseDate,
            );
            
            // Save to backend
            final service = InvestmentService();
            final newId = await service.saveInvestment(investment);
            
            print('Widget: Investment saved with ID: $newId');
            
            if (mounted) {
              // Immediately add to local list for instant feedback
              final newInvestment = InvestmentModel(
                id: newId,
                assetType: assetType,
                assetName: assetName,
                quantity: quantity,
                purchaseValue: purchaseValue,
                currency: currency,
                purchaseDate: purchaseDate,
              );
              
              setState(() {
                _investments = [...(_investments ?? []), newInvestment];
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $assetName'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Refresh in background to get price data
              _loadData(forceRefresh: true);
            }
          } catch (e) {
            print('Widget: Save failed - $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add investment: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildPortfolioSummary(double totalValue, double gainLoss, bool isDark) {
    final color = gainLoss >= 0
        ? (isDark ? const Color(0xFF5DADE2) : const Color(0xFF4A90E2))
        : (isDark ? Colors.redAccent : Colors.red);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Value',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${totalValue.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              gainLoss >= 0 ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${gainLoss >= 0 ? '+' : ''}${gainLoss.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(bool isDark) {
    // Get the first investment with price history
    final investmentWithHistory = _investments!.firstWhere(
      (inv) => inv.priceHistory != null && inv.priceHistory!.isNotEmpty,
      orElse: () => _investments!.first,
    );

    if (investmentWithHistory.priceHistory == null || 
        investmentWithHistory.priceHistory!.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          'Price history will appear after refresh',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      );
    }

    final history = investmentWithHistory.priceHistory!;
    
    // Create spots from price history
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price))
        .toList();

    // Determine if overall trend is positive
    final firstPrice = history.first.price;
    final lastPrice = history.last.price;
    final isPositive = lastPrice >= firstPrice;
    
    final lineColor = isPositive
        ? (isDark ? const Color(0xFF5DADE2) : const Color(0xFF4A90E2))
        : (isDark ? Colors.redAccent : Colors.red);

    return SizedBox(
      height: 80,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 40,
            color: isDark ? Colors.white54 : Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(
            localizations.noInvestmentsYet,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Investment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF4A90E2) : const Color(0xFF5DADE2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations localizations) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 32,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 8),
        Text(
          localizations.errorLoadingData,
          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _loadData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
          ),
          child: Text(localizations.retry, style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}


/// Investment List Dialog - Shows all investments in a popup
class _InvestmentListDialog extends StatelessWidget {
  final List<InvestmentModel> investments;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _InvestmentListDialog({
    required this.investments,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: 16,
        blur: 15.0,
        opacity: isDark ? 0.35 : 0.1,
        color: isDark ? const Color(0xFF1A3A4A) : Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations.investments,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.pop(context);
                        onAdd();
                      },
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Investment List
              Expanded(
                child: investments.isEmpty
                    ? _buildEmptyState(localizations, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: investments.length,
                        itemBuilder: (context, index) {
                          return _buildInvestmentCard(
                            context,
                            investments[index],
                            isDark,
                            onRefresh,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: isDark ? Colors.white54 : Colors.black38,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noInvestmentsYet,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentCard(
    BuildContext context,
    InvestmentModel investment,
    bool isDark,
    VoidCallback onRefresh,
  ) {
    final color = investment.isPositiveReturn()
        ? (isDark ? const Color(0xFF5DADE2) : const Color(0xFF4A90E2))
        : (isDark ? Colors.redAccent : Colors.red);

    final currentValue = investment.getCurrentValue();
    final gainLoss = investment.getGainLoss();
    final gainLossPercent = investment.getGainLossPercent();

    return GlassContainer(
      borderRadius: 12,
      opacity: isDark ? 0.2 : 0.05,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.assetName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        investment.assetType.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDialog(context, investment, onRefresh);
                      },
                      color: isDark ? Colors.white70 : Colors.black54,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        _showDeleteConfirmation(context, investment, onRefresh);
                      },
                      color: Colors.redAccent,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Investment details
            _buildDetailRow(
              'Quantity',
              '${investment.quantity} units',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Purchase Value',
              '${investment.getCurrencySymbol()}${investment.purchaseValue.toStringAsFixed(2)}',
              isDark,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Purchase Date',
              '${investment.purchaseDate.day}/${investment.purchaseDate.month}/${investment.purchaseDate.year}',
              isDark,
            ),
            
            if (investment.currentPrice != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Current Price',
                '${investment.getCurrencySymbol()}${investment.currentPrice!.toStringAsFixed(2)}',
                isDark,
              ),
            ],
            
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            
            // Current value and gain/loss
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Value',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${investment.getCurrencySymbol()}${currentValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(
                          investment.isPositiveReturn() ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${gainLossPercent >= 0 ? '+' : ''}${gainLossPercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${gainLoss >= 0 ? '+' : ''}${investment.getCurrencySymbol()}${gainLoss.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    InvestmentModel investment,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (context) => _EditInvestmentDialog(
        investment: investment,
        onSave: (assetType, assetName, quantity, purchaseValue, currency, purchaseDate) {
          // TODO: Call backend to update investment
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated $assetName'),
              backgroundColor: Colors.green,
            ),
          );
          onRefresh();
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    InvestmentModel investment,
    VoidCallback onRefresh,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A3A4A) : Colors.white,
        title: const Text('Delete Investment'),
        content: Text('Are you sure you want to delete ${investment.assetName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirmation dialog
              
              try {
                print('Widget: Starting delete for ${investment.id}');
                
                // Delete from backend
                final service = InvestmentService();
                await service.deleteInvestment(investment.id);
                
                print('Widget: Delete completed, closing dialog');
                
                // Close the investment list dialog too
                if (context.mounted) {
                  Navigator.pop(context); // Close the investment list dialog
                }
                
                // Wait a bit for dialogs to close
                await Future.delayed(const Duration(milliseconds: 150));
                
                print('Widget: Calling onRefresh');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted ${investment.assetName}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Refresh the data
                  onRefresh();
                }
              } catch (e) {
                print('Widget: Delete failed - $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Edit Investment Dialog
class _EditInvestmentDialog extends StatefulWidget {
  final InvestmentModel investment;
  final Function(
    AssetType assetType,
    String assetName,
    double quantity,
    double purchaseValue,
    Currency currency,
    DateTime purchaseDate,
  ) onSave;

  const _EditInvestmentDialog({
    required this.investment,
    required this.onSave,
  });

  @override
  State<_EditInvestmentDialog> createState() => _EditInvestmentDialogState();
}

class _EditInvestmentDialogState extends State<_EditInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _assetNameController;
  late TextEditingController _quantityController;
  late TextEditingController _purchaseValueController;
  
  late AssetType _assetType;
  late Currency _currency;
  late DateTime _purchaseDate;

  @override
  void initState() {
    super.initState();
    _assetNameController = TextEditingController(text: widget.investment.assetName);
    _quantityController = TextEditingController(text: widget.investment.quantity.toString());
    _purchaseValueController = TextEditingController(text: widget.investment.purchaseValue.toString());
    _assetType = widget.investment.assetType;
    _currency = widget.investment.currency;
    _purchaseDate = widget.investment.purchaseDate;
  }

  @override
  void dispose() {
    _assetNameController.dispose();
    _quantityController.dispose();
    _purchaseValueController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final assetName = _assetNameController.text.trim();
    final quantity = double.parse(_quantityController.text.trim());
    final purchaseValue = double.parse(_purchaseValueController.text.trim());

    widget.onSave(
      _assetType,
      assetName,
      quantity,
      purchaseValue,
      _currency,
      _purchaseDate,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: GlassContainer(
          borderRadius: 16,
          blur: 15.0,
          opacity: isDark ? 0.35 : 0.1,
          color: isDark ? const Color(0xFF1A3A4A) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Investment',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Asset Name field
                  TextFormField(
                    controller: _assetNameController,
                    decoration: InputDecoration(
                      labelText: 'Asset Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Asset name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Quantity field
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Must be a positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Purchase Value field
                  TextFormField(
                    controller: _purchaseValueController,
                    decoration: InputDecoration(
                      labelText: 'Purchase Value *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Purchase value is required';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Must be a positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(localizations.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(localizations.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
