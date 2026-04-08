import '../../models/profile_model.dart';

abstract class IDatabaseService {
  Future<dynamic> get database;

  // User operations
  Future<int> createUser({
    required String username,
    required String displayName,
    String? email,
    String? oauthProvider,
    String? oauthId,
    bool isGuest = false,
  });
  Future<Map<String, dynamic>?> getUserById(int userId);
  Future<Map<String, dynamic>?> getUserByUsername(String username);
  Future<Map<String, dynamic>?> getUserByOAuth(String provider, String oauthId);
  Future<List<Map<String, dynamic>>> getAllUsers();
  Future<void> updateUserLastLogin(int userId);
  Future<void> linkOAuthToUser(int userId, String provider, String oauthId, String email);
  Future<void> unlinkOAuthFromUser(int userId);

  // Transaction operations
  Future<int> insertTransaction(int userId, Map<String, dynamic> transaction);
  Future<List<Map<String, dynamic>>> getPostingsByTransactionId(int transactionId);
  Future<List<Map<String, dynamic>>> getTransactionsByUserId(int userId);
  Future<void> deleteTransaction(int transactionId);
  Future<void> deleteTransactionById(String transactionId);
  Future<void> markTransactionAsSynced(int transactionId);
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions(int userId);

  // Settings operations
  Future<void> setSetting(int userId, String key, String value);
  Future<String?> getSetting(int userId, String key);
  Future<Map<String, String>> getAllSettings(int userId);
  Future<void> deleteSetting(int userId, String key);

  // Profile operations
  Future<void> createProfile(Profile profile);
  Future<Map<String, dynamic>?> getProfileByUserId(int userId);
  Future<void> updateProfile(Profile profile);
  Future<void> deleteProfile(int userId);

  // Bill operations
  Future<int> insertBill(int userId, Map<String, dynamic> bill);
  Future<List<Map<String, dynamic>>> getBillsByUserId(int userId);
  Future<void> updateBill(int billId, Map<String, dynamic> bill);
  Future<void> deleteBill(int billId);

  // Investment operations
  Future<int> insertInvestment(int userId, Map<String, dynamic> investment);
  Future<List<Map<String, dynamic>>> getInvestmentsByUserId(int userId);
  Future<Map<String, dynamic>?> getInvestmentById(String investmentId);
  Future<void> updateInvestment(String investmentId, Map<String, dynamic> investment);
  Future<void> deleteInvestment(String investmentId);
  Future<void> markInvestmentAsSynced(String investmentId);
  Future<List<Map<String, dynamic>>> getUnsyncedInvestments(int userId);

  // Data consent
  Future<void> setUserDataConsent(int userId, bool consent);

  // Budget CRUD
  Future<int> insertBudget(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getBudgetsByUserId(int userId);
  Future<Map<String, dynamic>?> getActiveBudgetByUserId(int userId);
  Future<void> updateBudget(int id, Map<String, dynamic> data);
  Future<void> deleteBudget(int id);

  // Budget Category CRUD
  Future<int> insertBudgetCategory(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getBudgetCategoriesByBudgetId(int budgetId);
  Future<void> updateBudgetCategory(int id, Map<String, dynamic> data);
  Future<void> deleteBudgetCategory(int id);
  Future<void> deleteBudgetCategoriesByBudgetId(int budgetId);

  // Budget Period CRUD
  Future<int> insertBudgetPeriod(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getBudgetPeriodsByCategoryId(int categoryId);
  Future<Map<String, dynamic>?> getBudgetPeriodForDate(int categoryId, String date);
  Future<void> deleteBudgetPeriodsByCategoryId(int categoryId);

  // Notification Rule CRUD
  Future<int> insertNotificationRule(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getNotificationRulesByCategoryId(int categoryId);
  Future<void> updateNotificationRule(int id, Map<String, dynamic> data);
  Future<void> deleteNotificationRulesByCategoryId(int categoryId);

  // Budget spending queries
  Future<List<Map<String, dynamic>>> getExpensePostingsForPeriod(int userId, String startDate, String endDate);

  // AI Corrections
  Future<void> insertAICorrection(Map<String, dynamic> correction);
  Future<List<Map<String, dynamic>>> getAICorrections(String feature, {int limit = 10});

  // Utility
  Future<void> clearAllData();
  Future<void> clearUserData(int userId);
  Future<void> close();
  Future<void> resetConnection();
}
