import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/providers/auth_provider.dart';
import 'package:plutus_fe_prototype/providers/budget_provider.dart';
import 'package:plutus_fe_prototype/providers/settings_provider.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_budget_service.dart';
import 'package:plutus_fe_prototype/services/currency_service.dart';
import 'package:plutus_fe_prototype/theme/app_spacing.dart';
import 'package:plutus_fe_prototype/theme/app_radius.dart';

/// Common expense categories with their default account patterns and icons.
class _DefaultCategory {
  final String name;
  final String pattern;
  final String icon;
  const _DefaultCategory(this.name, this.pattern, this.icon);
}

const _defaultCategories = [
  _DefaultCategory('Food & Dining', 'Expenses:Food', '🍔'),
  _DefaultCategory('Groceries', 'Expenses:Groceries', '🛒'),
  _DefaultCategory('Transportation', 'Expenses:Transportation', '🚗'),
  _DefaultCategory('Housing & Rent', 'Expenses:Housing', '🏠'),
  _DefaultCategory('Utilities', 'Expenses:Utilities', '💡'),
  _DefaultCategory('Entertainment', 'Expenses:Entertainment', '🎮'),
  _DefaultCategory('Shopping', 'Expenses:Shopping', '🛍️'),
  _DefaultCategory('Healthcare', 'Expenses:Healthcare', '🏥'),
  _DefaultCategory('Education', 'Expenses:Education', '📚'),
  _DefaultCategory('Insurance', 'Expenses:Insurance', '🛡️'),
  _DefaultCategory('Subscriptions', 'Expenses:Subscriptions', '📱'),
  _DefaultCategory('Personal Care', 'Expenses:Personal', '💇'),
  _DefaultCategory('Travel', 'Expenses:Travel', '✈️'),
  _DefaultCategory('Gifts & Donations', 'Expenses:Gifts', '🎁'),
  _DefaultCategory('Bills & Fees', 'Expenses:Bills', '📄'),
];

class BudgetSettingsSheet extends StatefulWidget {
  const BudgetSettingsSheet({super.key});

  @override
  State<BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends State<BudgetSettingsSheet> {
  late IBudgetService _budgetService;
  bool _alertEnabled = false;
  List<String> _userAccounts = [];

  @override
  void initState() {
    super.initState();
    _budgetService = GetIt.I<IBudgetService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentUserId != null) {
          final provider = context.read<BudgetProvider>();
          provider.setCurrentUser(authProvider.currentUserId!);
          _budgetService.setCurrentUser(authProvider.currentUserId!);
          provider.loadBudget();
          _loadUserAccounts();
        }
      }
    });
  }

  Future<void> _loadUserAccounts() async {
    final suggestions = await _budgetService.suggestCategoriesFromAccounts();
    if (mounted) {
      setState(() {
        _userAccounts =
            suggestions.map((s) => s.accountName).toList();
      });
    }
  }

  String _currencySymbol(String code) {
    return AppCurrency.fromCode(code).symbol;
  }

  String _formatAmount(double amount, String currencyCode) {
    return CurrencyService.formatAmount(amount, currencyCode);
  }

  // ---------------------------------------------------------------------------
  // Budget creation
  // ---------------------------------------------------------------------------

  Future<void> _createNewBudget() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in first')),
          );
        }
        return;
      }
      _budgetService.setCurrentUser(authProvider.currentUserId!);

      // Use the app's current currency setting
      final settingsProvider = context.read<SettingsProvider>();
      final currency = settingsProvider.currency;
      final currencyCode =
          currency.isOriginal ? 'USD' : currency.code;

      await _budgetService.createBudget(
        name: 'My Budget',
        mode: BudgetMode.spendingLimit,
        periodType: BudgetPeriodType.monthly,
        currencyCode: currencyCode,
      );
      await _reloadProvider();
      await _loadUserAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating budget: $e')),
        );
      }
    }
  }

  Future<void> _reloadProvider() async {
    if (mounted) {
      await context.read<BudgetProvider>().loadBudget();
    }
  }

  // ---------------------------------------------------------------------------
  // Add Category Dialog — dropdown with common + user accounts + "Other"
  // ---------------------------------------------------------------------------

  Future<void> _showAddCategoryDialog(Budget budget) async {
    final amountController = TextEditingController();
    final customNameController = TextEditingController();
    final customPatternController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final currency = budget.currencyCode;
    final symbol = _currencySymbol(currency);

    // Build dropdown items: defaults + user accounts + Other
    final existingPatterns = budget.categories
        .expand((c) => c.accountPatterns)
        .map((p) => p.toLowerCase())
        .toSet();

    // Filter out already-budgeted defaults
    final availableDefaults = _defaultCategories
        .where((d) => !existingPatterns.contains(d.pattern.toLowerCase()))
        .toList();

    // Filter out already-budgeted user accounts
    final availableUserAccounts = _userAccounts
        .where((a) => !existingPatterns.contains(a.toLowerCase()))
        .toList();

    String? selectedKey; // "default:index", "user:accountName", or "other"
    bool isOther = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add Category'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      isExpanded: true,
                      initialValue: selectedKey,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select a category' : null,
                      items: [
                        // Common categories
                        if (availableDefaults.isNotEmpty) ...[
                          DropdownMenuItem<String>(
                            enabled: false,
                            value: '__header_common__',
                            child: Text(
                              'Common Categories',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                            ),
                          ),
                          ...availableDefaults.asMap().entries.map((e) {
                            final d = e.value;
                            return DropdownMenuItem<String>(
                              value: 'default:${e.key}',
                              child: Row(
                                children: [
                                  Text(d.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(d.name, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // User's actual accounts from transactions
                        if (availableUserAccounts.isNotEmpty) ...[
                          DropdownMenuItem<String>(
                            enabled: false,
                            value: '__header_user__',
                            child: Text(
                              'From Your Transactions',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                            ),
                          ),
                          ...availableUserAccounts.map((account) {
                            final parts = account.split(':');
                            final display =
                                parts.length > 1 ? parts.sublist(1).join(':') : account;
                            return DropdownMenuItem<String>(
                              value: 'user:$account',
                              child: Row(
                                children: [
                                  const Text('📊', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(display, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // Other (custom)
                        const DropdownMenuItem<String>(
                          value: 'other',
                          child: Row(
                            children: [
                              Text('✏️', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Text('Other (custom)'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedKey = val;
                          isOther = val == 'other';
                        });
                      },
                    ),

                    // Custom name + pattern fields (only shown for "Other")
                    if (isOther) ...[
                      SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: customNameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g., Pet Care',
                        ),
                        validator: (v) => isOther && (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: customPatternController,
                        decoration: const InputDecoration(
                          labelText: 'Account Pattern',
                          hintText: 'e.g., Expenses:Pets',
                          helperText: 'Matches transactions starting with this prefix',
                        ),
                        validator: (v) => isOther && (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ],

                    SizedBox(height: AppSpacing.md),

                    // Budget amount with correct currency
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Budget Amount',
                        prefixText: '$symbol ',
                        suffixText: currency,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  String name;
                  List<String> patterns;
                  String? icon;

                  if (isOther) {
                    name = customNameController.text.trim();
                    patterns = customPatternController.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                  } else if (selectedKey != null &&
                      selectedKey!.startsWith('default:')) {
                    final idx = int.parse(selectedKey!.split(':')[1]);
                    final d = availableDefaults[idx];
                    name = d.name;
                    patterns = [d.pattern];
                    icon = d.icon;
                  } else if (selectedKey != null &&
                      selectedKey!.startsWith('user:')) {
                    final account = selectedKey!.substring(5);
                    final parts = account.split(':');
                    name = parts.length > 1 ? parts.sublist(1).join(' ') : account;
                    patterns = [account];
                  } else {
                    return;
                  }

                  Navigator.of(ctx).pop();
                  await _budgetService.addCategory(
                    budgetId: budget.id!,
                    name: name,
                    accountPatterns: patterns,
                    amount: double.parse(amountController.text.trim()),
                    icon: icon,
                  );
                  await _reloadProvider();
                  await _loadUserAccounts();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category CRUD
  // ---------------------------------------------------------------------------

  Future<void> _deleteCategory(int categoryId) async {
    await _budgetService.removeCategory(categoryId);
    await _reloadProvider();
  }

  Future<void> _toggleRollover(int categoryId, bool value) async {
    await _budgetService.updateCategory(categoryId, rolloverEnabled: value);
    await _reloadProvider();
  }

  // ---------------------------------------------------------------------------
  // Currency section
  // ---------------------------------------------------------------------------

  Widget _buildCurrencySection(Budget budget) {
    final currencies = AppCurrency.values
        .where((c) => !c.isOriginal)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('CURRENCY'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: DropdownButtonFormField<String>(
            initialValue: budget.currencyCode,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: currencies.map((c) {
              return DropdownMenuItem<String>(
                value: c.code,
                child: Text('${c.symbol}  ${c.code} — ${c.displayName}'),
              );
            }).toList(),
            onChanged: (code) async {
              if (code != null) {
                await _budgetService.updateBudget(
                  budget.id!,
                  currencyCode: code,
                );
                await _reloadProvider();
              }
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // UI Helpers
  // ---------------------------------------------------------------------------

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: AppRadius.borderSm,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildBudgetModeSection(Budget budget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('BUDGET MODE'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SegmentedButton<BudgetMode>(
            segments: const [
              ButtonSegment(
                value: BudgetMode.spendingLimit,
                label: Text('Spending Limits'),
                icon: Icon(Icons.shield_outlined),
              ),
              ButtonSegment(
                value: BudgetMode.zeroBased,
                label: Text('Zero-Based'),
                icon: Icon(Icons.balance_outlined),
              ),
            ],
            selected: {budget.mode},
            onSelectionChanged: (selected) async {
              await _budgetService.updateBudget(budget.id!, mode: selected.first);
              await _reloadProvider();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetPeriodSection(Budget budget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('BUDGET PERIOD'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SegmentedButton<BudgetPeriodType>(
            segments: const [
              ButtonSegment(value: BudgetPeriodType.monthly, label: Text('Monthly')),
              ButtonSegment(value: BudgetPeriodType.weekly, label: Text('Weekly')),
              ButtonSegment(value: BudgetPeriodType.biweekly, label: Text('Biweekly')),
            ],
            selected: {budget.periodType},
            onSelectionChanged: (selected) async {
              await _budgetService.updateBudget(
                  budget.id!, periodType: selected.first);
              await _reloadProvider();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BudgetCategory cat, String currencyCode) {
    final patterns = cat.accountPatterns.join(', ');
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                if (cat.icon != null && cat.icon!.isNotEmpty)
                  Text(cat.icon!, style: const TextStyle(fontSize: 24))
                else
                  const Icon(Icons.category_outlined, size: 24),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (patterns.isNotEmpty)
                        Text(
                          patterns,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatAmount(cat.budgetedAmount, currencyCode),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) async {
                    if (action == 'delete' && cat.id != null) {
                      await _deleteCategory(cat.id!);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rollover', style: Theme.of(context).textTheme.bodySmall),
                Switch(
                  value: cat.rolloverEnabled,
                  onChanged: cat.id != null
                      ? (val) => _toggleRollover(cat.id!, val)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(Budget budget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('CATEGORIES'),
        if (budget.categories.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              'No categories yet. Add one below.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...budget.categories
              .map((cat) => _buildCategoryCard(cat, budget.currencyCode)),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: OutlinedButton.icon(
            onPressed: () => _showAddCategoryDialog(budget),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedCategoriesSection(Budget budget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('SUGGESTED FROM TRANSACTIONS'),
        FutureBuilder<List<SuggestedCategory>>(
          future: _budgetService.suggestCategoriesFromAccounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  'No suggestions available.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              );
            }

            final suggestions = snapshot.data!.take(5).toList();
            return Column(
              children: suggestions.map((suggestion) {
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(suggestion.suggestedName),
                  subtitle: Text(
                    '${suggestion.accountName} · ${_formatAmount(suggestion.recentSpending, budget.currencyCode)} in 3 months',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final amount = suggestion.recentSpending / 3;
                      await _budgetService.addCategory(
                        budgetId: budget.id!,
                        name: suggestion.suggestedName,
                        accountPatterns: [suggestion.accountName],
                        amount: amount,
                      );
                      await _reloadProvider();
                      await _loadUserAccounts();
                    },
                    child: const Text('+ Add'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('NOTIFICATIONS'),
        SwitchListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          title: const Text('Alert at spending threshold'),
          subtitle: const Text('Default: 90%'),
          value: _alertEnabled,
          onChanged: (val) => setState(() => _alertEnabled = val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<BudgetProvider>(
          builder: (context, provider, _) {
            final budget = provider.activeBudget;

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  _buildHandleBar(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      'Budget Settings',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (provider.isLoading)
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.xxxl),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (budget == null)
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'No budget yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Create a budget to start tracking your spending by category.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: _createNewBudget,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Budget'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _buildBudgetModeSection(budget),
                    SizedBox(height: AppSpacing.md),
                    _buildBudgetPeriodSection(budget),
                    SizedBox(height: AppSpacing.md),
                    _buildCurrencySection(budget),
                    SizedBox(height: AppSpacing.md),
                    _buildCategoriesSection(budget),
                    SizedBox(height: AppSpacing.md),
                    _buildSuggestedCategoriesSection(budget),
                    SizedBox(height: AppSpacing.md),
                    _buildNotificationsSection(),
                    SizedBox(height: AppSpacing.xxxl),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
