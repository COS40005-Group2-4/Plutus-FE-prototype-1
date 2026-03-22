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
  
  Future<void> setString(int userId, String key, String value) async {
    try {
      await _db.setSetting(userId, key, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting string value: $e');
      }
      rethrow;
    }
  }
  
  Future<String?> getString(int userId, String key, {String? defaultValue}) async {
    try {
      final value = await _db.getSetting(userId, key);
      return value ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting string value: $e');
      }
      return defaultValue;
    }
  }
  
  Future<void> setInt(int userId, String key, int value) async {
    await setString(userId, key, value.toString());
  }
  
  Future<int?> getInt(int userId, String key, {int? defaultValue}) async {
    final value = await getString(userId, key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
  
  Future<void> setDouble(int userId, String key, double value) async {
    await setString(userId, key, value.toString());
  }
  
  Future<double?> getDouble(int userId, String key, {double? defaultValue}) async {
    final value = await getString(userId, key);
    if (value == null) return defaultValue;
    return double.tryParse(value) ?? defaultValue;
  }
  
  Future<void> setBool(int userId, String key, bool value) async {
    await setString(userId, key, value.toString());
  }
  
  Future<bool?> getBool(int userId, String key, {bool? defaultValue}) async {
    final value = await getString(userId, key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }
  
  Future<void> setMap(int userId, String key, Map<String, dynamic> value) async {
    await setString(userId, key, json.encode(value));
  }
  
  Future<Map<String, dynamic>?> getMap(int userId, String key) async {
    final value = await getString(userId, key);
    if (value == null) return null;
    try {
      return json.decode(value) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding map: $e');
      }
      return null;
    }
  }
  
  Future<void> setList(int userId, String key, List<dynamic> value) async {
    await setString(userId, key, json.encode(value));
  }
  
  Future<List<dynamic>?> getList(int userId, String key) async {
    final value = await getString(userId, key);
    if (value == null) return null;
    try {
      return json.decode(value) as List<dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding list: $e');
      }
      return null;
    }
  }
  
  Future<Map<String, String>> getAllSettings(int userId) async {
    try {
      return await _db.getAllSettings(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all settings: $e');
      }
      return {};
    }
  }
  
  Future<void> deleteSetting(int userId, String key) async {
    try {
      await _db.deleteSetting(userId, key);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting setting: $e');
      }
      rethrow;
    }
  }
  
  // Convenience methods for common settings
  Future<void> setThemeMode(int userId, String mode) async {
    await setString(userId, keyThemeMode, mode);
  }
  
  Future<String> getThemeMode(int userId) async {
    return await getString(userId, keyThemeMode, defaultValue: 'system') ?? 'system';
  }
  
  Future<void> setDefaultCurrency(int userId, String currency) async {
    await setString(userId, keyCurrency, currency);
  }
  
  Future<String> getDefaultCurrency(int userId) async {
    return await getString(userId, keyCurrency, defaultValue: 'VND') ?? 'VND';
  }
  
  Future<void> setNotificationsEnabled(int userId, bool enabled) async {
    await setBool(userId, keyNotifications, enabled);
  }
  
  Future<bool> getNotificationsEnabled(int userId) async {
    return await getBool(userId, keyNotifications, defaultValue: true) ?? true;
  }
  
  Future<void> setAutoBackupEnabled(int userId, bool enabled) async {
    await setBool(userId, keyAutoBackup, enabled);
  }
  
  Future<bool> getAutoBackupEnabled(int userId) async {
    return await getBool(userId, keyAutoBackup, defaultValue: false) ?? false;
  }
  
  Future<void> setLastSyncTime(int userId, DateTime time) async {
    await setString(userId, keyLastSyncTime, time.toIso8601String());
  }
  
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
