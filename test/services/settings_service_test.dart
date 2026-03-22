import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/services/settings_service.dart';

import '../helpers/mock_services.mocks.dart';

void main() {
  late MockIDatabaseService mockDb;
  late SettingsService service;

  const int userId = 1;

  setUp(() {
    mockDb = MockIDatabaseService();
    service = SettingsService(db: mockDb);
  });

  group('setString / getString', () {
    test('round-trip stores and retrieves a string value', () async {
      when(mockDb.setSetting(userId, 'key', 'value'))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, 'key'))
          .thenAnswer((_) async => 'value');

      await service.setString(userId, 'key', 'value');
      final result = await service.getString(userId, 'key');

      expect(result, 'value');
      verify(mockDb.setSetting(userId, 'key', 'value')).called(1);
      verify(mockDb.getSetting(userId, 'key')).called(1);
    });

    test('getString returns defaultValue when key not found', () async {
      when(mockDb.getSetting(userId, 'missing'))
          .thenAnswer((_) async => null);

      final result =
          await service.getString(userId, 'missing', defaultValue: 'fallback');

      expect(result, 'fallback');
    });

    test('getString returns null when no default and key not found', () async {
      when(mockDb.getSetting(userId, 'missing'))
          .thenAnswer((_) async => null);

      final result = await service.getString(userId, 'missing');

      expect(result, isNull);
    });

    test('getString returns defaultValue on error', () async {
      when(mockDb.getSetting(userId, 'key'))
          .thenThrow(Exception('DB error'));

      final result =
          await service.getString(userId, 'key', defaultValue: 'safe');

      expect(result, 'safe');
    });

    test('setString rethrows on error', () async {
      when(mockDb.setSetting(userId, 'key', 'value'))
          .thenThrow(Exception('write error'));

      expect(
        () => service.setString(userId, 'key', 'value'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getInt / setInt', () {
    test('round-trip stores and retrieves an int value', () async {
      when(mockDb.setSetting(userId, 'count', '42'))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, 'count'))
          .thenAnswer((_) async => '42');

      await service.setInt(userId, 'count', 42);
      final result = await service.getInt(userId, 'count');

      expect(result, 42);
    });

    test('getInt returns defaultValue when key not found', () async {
      when(mockDb.getSetting(userId, 'count'))
          .thenAnswer((_) async => null);

      final result =
          await service.getInt(userId, 'count', defaultValue: 0);

      expect(result, 0);
    });

    test('getInt returns defaultValue for non-numeric string', () async {
      when(mockDb.getSetting(userId, 'count'))
          .thenAnswer((_) async => 'not_a_number');

      final result =
          await service.getInt(userId, 'count', defaultValue: -1);

      expect(result, -1);
    });
  });

  group('getBool / setBool', () {
    test('round-trip stores and retrieves true', () async {
      when(mockDb.setSetting(userId, 'flag', 'true'))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, 'flag'))
          .thenAnswer((_) async => 'true');

      await service.setBool(userId, 'flag', true);
      final result = await service.getBool(userId, 'flag');

      expect(result, true);
    });

    test('round-trip stores and retrieves false', () async {
      when(mockDb.setSetting(userId, 'flag', 'false'))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, 'flag'))
          .thenAnswer((_) async => 'false');

      await service.setBool(userId, 'flag', false);
      final result = await service.getBool(userId, 'flag');

      expect(result, false);
    });

    test('getBool returns defaultValue when key not found', () async {
      when(mockDb.getSetting(userId, 'flag'))
          .thenAnswer((_) async => null);

      final result =
          await service.getBool(userId, 'flag', defaultValue: true);

      expect(result, true);
    });
  });

  group('getDouble / setDouble', () {
    test('round-trip stores and retrieves a double', () async {
      when(mockDb.setSetting(userId, 'rate', '3.14'))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, 'rate'))
          .thenAnswer((_) async => '3.14');

      await service.setDouble(userId, 'rate', 3.14);
      final result = await service.getDouble(userId, 'rate');

      expect(result, closeTo(3.14, 0.001));
    });

    test('getDouble returns defaultValue for non-numeric string', () async {
      when(mockDb.getSetting(userId, 'rate'))
          .thenAnswer((_) async => 'abc');

      final result =
          await service.getDouble(userId, 'rate', defaultValue: 0.0);

      expect(result, 0.0);
    });
  });

  group('getMap / setMap', () {
    test('round-trip stores and retrieves a map', () async {
      final map = {'key1': 'val1', 'key2': 42};
      final encoded = json.encode(map);

      when(mockDb.setSetting(userId, 'mapKey', encoded))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, 'mapKey'))
          .thenAnswer((_) async => encoded);

      await service.setMap(userId, 'mapKey', map);
      final result = await service.getMap(userId, 'mapKey');

      expect(result, isNotNull);
      expect(result!['key1'], 'val1');
      expect(result['key2'], 42);
    });

    test('getMap returns null for corrupted JSON', () async {
      when(mockDb.getSetting(userId, 'mapKey'))
          .thenAnswer((_) async => '{not valid json!!!');

      final result = await service.getMap(userId, 'mapKey');

      expect(result, isNull);
    });

    test('getMap returns null when key not found', () async {
      when(mockDb.getSetting(userId, 'mapKey'))
          .thenAnswer((_) async => null);

      final result = await service.getMap(userId, 'mapKey');

      expect(result, isNull);
    });
  });

  group('getList / setList', () {
    test('round-trip stores and retrieves a list', () async {
      final list = [1, 'two', 3.0];
      final encoded = json.encode(list);

      when(mockDb.setSetting(userId, 'listKey', encoded))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, 'listKey'))
          .thenAnswer((_) async => encoded);

      await service.setList(userId, 'listKey', list);
      final result = await service.getList(userId, 'listKey');

      expect(result, isNotNull);
      expect(result!.length, 3);
    });

    test('getList returns null for corrupted JSON', () async {
      when(mockDb.getSetting(userId, 'listKey'))
          .thenAnswer((_) async => 'not a list');

      final result = await service.getList(userId, 'listKey');

      expect(result, isNull);
    });
  });

  group('getAllSettings', () {
    test('returns settings map from database', () async {
      when(mockDb.getAllSettings(userId))
          .thenAnswer((_) async => {'theme': 'dark', 'lang': 'en'});

      final result = await service.getAllSettings(userId);

      expect(result['theme'], 'dark');
      expect(result['lang'], 'en');
    });

    test('returns empty map on error', () async {
      when(mockDb.getAllSettings(userId))
          .thenThrow(Exception('DB error'));

      final result = await service.getAllSettings(userId);

      expect(result, isEmpty);
    });
  });

  group('deleteSetting', () {
    test('delegates to db deleteSetting', () async {
      when(mockDb.deleteSetting(userId, 'key'))
          .thenAnswer((_) async {});

      await service.deleteSetting(userId, 'key');

      verify(mockDb.deleteSetting(userId, 'key')).called(1);
    });

    test('rethrows on error', () async {
      when(mockDb.deleteSetting(userId, 'key'))
          .thenThrow(Exception('delete error'));

      expect(
        () => service.deleteSetting(userId, 'key'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('convenience methods', () {
    test('getThemeMode returns system as default', () async {
      when(mockDb.getSetting(userId, SettingsService.keyThemeMode))
          .thenAnswer((_) async => null);

      final result = await service.getThemeMode(userId);

      expect(result, 'system');
    });

    test('setThemeMode stores the value', () async {
      when(mockDb.setSetting(
              userId, SettingsService.keyThemeMode, 'dark'))
          .thenAnswer((_) async {});

      await service.setThemeMode(userId, 'dark');

      verify(mockDb.setSetting(
              userId, SettingsService.keyThemeMode, 'dark'))
          .called(1);
    });

    test('getDefaultCurrency returns VND as default', () async {
      when(mockDb.getSetting(userId, SettingsService.keyCurrency))
          .thenAnswer((_) async => null);

      final result = await service.getDefaultCurrency(userId);

      expect(result, 'VND');
    });

    test('getNotificationsEnabled returns true as default', () async {
      when(mockDb.getSetting(userId, SettingsService.keyNotifications))
          .thenAnswer((_) async => null);

      final result = await service.getNotificationsEnabled(userId);

      expect(result, true);
    });

    test('getAutoBackupEnabled returns false as default', () async {
      when(mockDb.getSetting(userId, SettingsService.keyAutoBackup))
          .thenAnswer((_) async => null);

      final result = await service.getAutoBackupEnabled(userId);

      expect(result, false);
    });

    test('setLastSyncTime and getLastSyncTime round-trip', () async {
      final time = DateTime(2024, 6, 15, 10, 30);
      final iso = time.toIso8601String();

      when(mockDb.setSetting(userId, SettingsService.keyLastSyncTime, iso))
          .thenAnswer((_) async {});
      when(mockDb.getSetting(userId, SettingsService.keyLastSyncTime))
          .thenAnswer((_) async => iso);

      await service.setLastSyncTime(userId, time);
      final result = await service.getLastSyncTime(userId);

      expect(result, time);
    });

    test('getLastSyncTime returns null when not set', () async {
      when(mockDb.getSetting(userId, SettingsService.keyLastSyncTime))
          .thenAnswer((_) async => null);

      final result = await service.getLastSyncTime(userId);

      expect(result, isNull);
    });

    test('getLastSyncTime returns null for invalid date string', () async {
      when(mockDb.getSetting(userId, SettingsService.keyLastSyncTime))
          .thenAnswer((_) async => 'not-a-date');

      final result = await service.getLastSyncTime(userId);

      expect(result, isNull);
    });
  });
}
