abstract class ISettingsService {
  // Core typed accessors
  Future<void> setString(int userId, String key, String value);
  Future<String?> getString(int userId, String key, {String? defaultValue});
  Future<void> setInt(int userId, String key, int value);
  Future<int?> getInt(int userId, String key, {int? defaultValue});
  Future<void> setDouble(int userId, String key, double value);
  Future<double?> getDouble(int userId, String key, {double? defaultValue});
  Future<void> setBool(int userId, String key, bool value);
  Future<bool?> getBool(int userId, String key, {bool? defaultValue});
  Future<void> setMap(int userId, String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getMap(int userId, String key);
  Future<void> setList(int userId, String key, List<dynamic> value);
  Future<List<dynamic>?> getList(int userId, String key);
  Future<Map<String, String>> getAllSettings(int userId);
  Future<void> deleteSetting(int userId, String key);

  // Convenience methods
  Future<void> setThemeMode(int userId, String mode);
  Future<String> getThemeMode(int userId);
  Future<void> setDefaultCurrency(int userId, String currency);
  Future<String> getDefaultCurrency(int userId);
  Future<void> setNotificationsEnabled(int userId, bool enabled);
  Future<bool> getNotificationsEnabled(int userId);
  Future<void> setAutoBackupEnabled(int userId, bool enabled);
  Future<bool> getAutoBackupEnabled(int userId);
  Future<void> setLastSyncTime(int userId, DateTime time);
  Future<DateTime?> getLastSyncTime(int userId);
}
