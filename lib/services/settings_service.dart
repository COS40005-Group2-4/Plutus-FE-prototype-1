import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'interfaces/i_database_service.dart';
import 'interfaces/i_settings_service.dart';
import '../di/service_locator.dart';

class SettingsService implements ISettingsService {
  final IDatabaseService _db;

  SettingsService({IDatabaseService? db}) : _db = db ?? sl<IDatabaseService>();
  
  // Common setting keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyCurrency = 'default_currency';
  static const String keyNotifications = 'notifications_enabled';
  static const String keyAutoBackup = 'auto_backup_enabled';
  static const String keyLastSyncTime = 'last_sync_time';
  
  @override
  Future<void> setString(int userId, String key, String value) async {
    try {
      await _db.setSetting(userId, key, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting string value: $e');
      }
      rethrow;
    }
  }
  
  @override
  Future<String?> getString(int userId, String key, {String? defaultValue}) async {
    try {
      final value = await _db.getSetting(userId, key);
      return value ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting string value: $e');
      }
      return defaultValue;
    }
  }
  
  @override
  Future<void> setInt(int userId, String key, int value) async {
    await setString(userId, key, value.toString());
  }
  
  @override
  Future<int?> getInt(int userId, String key, {int? defaultValue}) async {
    final value = await getString(userId, key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
  
  @override
  Future<void> setDouble(int userId, String key, double value) async {
    await setString(userId, key, value.toString());
  }
  
  @override
  Future<double?> getDouble(int userId, String key, {double? defaultValue}) async {
    final value = await getString(userId, key);
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }
  
  @override
  Future<void> setBool(int userId, String key, bool value) async {
    await setString(userId, key, value.toString());
  }
  
  @override
  Future<bool?> getBool(int userId, String key, {bool? defaultValue}) async {
    final value = await getString(userId, key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }
  
  @override
  Future<void> setMap(int userId, String key, Map<String, dynamic> value) async {
    await setString(userId, key, json.encode(value));
  }
  
  @override
  Future<Map<String, dynamic>?> getMap(int userId, String key) async {
    final value = await getString(userId, key);
    if (value == null) return null;
    try {
      return json.decode(value) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error decoding map: $e');
      }
      return null;
    }
  }
  
  @override
  Future<void> setList(int userId, String key, List<dynamic> value) async {
    await setString(userId, key, json.encode(value));
  }
  
  @override
  Future<List<dynamic>?> getList(int userId, String key) async {
    final value = await getString(userId, key);
    if (value == null) return null;
    try {
      return json.decode(value) as List<dynamic>;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error decoding list: $e');
      }
      return null;
    }
  }
  
  @override
  Future<Map<String, String>> getAllSettings(int userId) async {
    try {
      return await _db.getAllSettings(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all settings: $e');
      }
      return {};
    }
  }
  
  @override
  Future<void> deleteSetting(int userId, String key) async {
    try {
      await _db.deleteSetting(userId, key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting setting: $e');
      }
      rethrow;
    }
  }
  
  // Convenience methods for common settings
  @override
  Future<void> setThemeMode(int userId, String mode) async {
    await setString(userId, keyThemeMode, mode);
  }
  
  @override
  Future<String> getThemeMode(int userId) async {
    return await getString(userId, keyThemeMode, defaultValue: 'system') ?? 'system';
  }
  
  @override
  Future<void> setDefaultCurrency(int userId, String currency) async {
    await setString(userId, keyCurrency, currency);
  }
  
  @override
  Future<String> getDefaultCurrency(int userId) async {
    return await getString(userId, keyCurrency, defaultValue: 'VND') ?? 'VND';
  }
  
  @override
  Future<void> setNotificationsEnabled(int userId, bool enabled) async {
    await setBool(userId, keyNotifications, enabled);
  }
  
  @override
  Future<bool> getNotificationsEnabled(int userId) async {
    return await getBool(userId, keyNotifications, defaultValue: true) ?? true;
  }
  
  @override
  Future<void> setAutoBackupEnabled(int userId, bool enabled) async {
    await setBool(userId, keyAutoBackup, enabled);
  }
  
  @override
  Future<bool> getAutoBackupEnabled(int userId) async {
    return await getBool(userId, keyAutoBackup, defaultValue: false) ?? false;
  }
  
  @override
  Future<void> setLastSyncTime(int userId, DateTime time) async {
    await setString(userId, keyLastSyncTime, time.toIso8601String());
  }
  
  @override
  Future<DateTime?> getLastSyncTime(int userId) async {
    final value = await getString(userId, keyLastSyncTime);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }
}
