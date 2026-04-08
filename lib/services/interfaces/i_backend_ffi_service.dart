/// Interface for the Go FFI backend computation engine.
///
/// All methods accept and return raw JSON strings.
/// The Go backend is stateless — call [constructJournal] first to load state,
/// then use mutation and query methods. Callers parse responses and check
/// for error codes (non-200).
abstract class IBackendFfiService {
  /// Whether the native library loaded successfully.
  bool get isAvailable;

  // -- Lifecycle --

  /// Initialize the Go journal from a full JournalJSON dump.
  /// Returns ErrorJSON (code 200 on success).
  String constructJournal(String journalJson);

  /// Serialize the current Go journal to JournalJSON.
  /// Returns JournalJSON string or ErrorJSON.
  String dumpJournal();

  // -- Transactions --

  /// Add a balanced transaction. Returns ErrorJSON.
  String addTransaction(String transactionJson);

  /// Add an investment transaction with auto-balance. Returns ErrorJSON.
  String addInvestment(String transactionJson);

  // -- Budgets --

  /// Add or replace a budget. Returns ErrorJSON.
  String addBudget(String budgetJson);

  /// Delete a budget by account name. Returns ErrorJSON.
  String deleteBudget(String accountName);

  /// Generate a budget report for a date range. Returns BudgetReport or ErrorJSON.
  String budgetReport(String requestJson);

  // -- Rates --

  /// Add an explicit exchange rate. Returns ErrorJSON.
  String addRate(String rateJson);

  /// Query exchange rate between two commodities. Returns RateJSON or ErrorJSON.
  String getRate(String requestJson);

  // -- Queries --

  /// List all tracked account names. Returns JSON array of strings or ErrorJSON.
  String accountList();

  /// List all known commodity symbols. Returns JSON array of strings or ErrorJSON.
  String commodities();

  // -- Reports --

  /// Get ROI/IRR investment report. Returns InvestmentReport or ErrorJSON.
  String getInvestmentReport(String requestJson);

  /// Get income report (all income/expense accounts). Returns IncomeReport or ErrorJSON.
  String getIncomeReport();

  /// Get monthly savings report. Returns SavingsReport or ErrorJSON.
  String getSavingsReport(String requestJson);
}
