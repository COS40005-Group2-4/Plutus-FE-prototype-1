import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/backup_models.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('VersionEntry', () {
    group('construction', () {
      test('creates instance with all required fields', () {
        final entry = createTestVersionEntry();

        expect(entry.s3ObjectKey, 'backups/1/1704067200000.db');
        expect(entry.timestamp, DateTime(2024, 1, 1));
        expect(entry.fileSizeBytes, 1024);
        expect(entry.checksum, 'abc123');
      });

      test('creates instance with custom values', () {
        final timestamp = DateTime(2024, 6, 15);
        final entry = createTestVersionEntry(
          s3ObjectKey: 'backups/2/custom.db',
          timestamp: timestamp,
          fileSizeBytes: 2048,
          checksum: 'def456',
        );

        expect(entry.s3ObjectKey, 'backups/2/custom.db');
        expect(entry.timestamp, timestamp);
        expect(entry.fileSizeBytes, 2048);
        expect(entry.checksum, 'def456');
      });
    });

    group('Equatable', () {
      test('identical entries are equal', () {
        final e1 = createTestVersionEntry();
        final e2 = createTestVersionEntry();

        expect(e1, e2);
        expect(e1.hashCode, e2.hashCode);
      });

      test('entries with different s3ObjectKeys are not equal', () {
        final e1 = createTestVersionEntry(s3ObjectKey: 'backups/1/a.db');
        final e2 = createTestVersionEntry(s3ObjectKey: 'backups/1/b.db');

        expect(e1, isNot(e2));
      });

      test('entries with different checksums are not equal', () {
        final e1 = createTestVersionEntry(checksum: 'abc');
        final e2 = createTestVersionEntry(checksum: 'xyz');

        expect(e1, isNot(e2));
      });

      test('entries with different timestamps are not equal', () {
        final e1 = createTestVersionEntry(timestamp: DateTime(2024, 1, 1));
        final e2 = createTestVersionEntry(timestamp: DateTime(2024, 6, 1));

        expect(e1, isNot(e2));
      });

      test('entries with different file sizes are not equal', () {
        final e1 = createTestVersionEntry(fileSizeBytes: 1024);
        final e2 = createTestVersionEntry(fileSizeBytes: 2048);

        expect(e1, isNot(e2));
      });
    });

    group('props', () {
      test('includes all four fields', () {
        final entry = createTestVersionEntry();

        expect(entry.props.length, 4);
        expect(entry.props, contains('backups/1/1704067200000.db'));
        expect(entry.props, contains(1024));
        expect(entry.props, contains('abc123'));
      });
    });
  });

  group('ConflictResult', () {
    test('has all expected values', () {
      expect(ConflictResult.values.length, 5);
      expect(ConflictResult.values, contains(ConflictResult.match));
      expect(ConflictResult.values, contains(ConflictResult.mismatch));
      expect(ConflictResult.values, contains(ConflictResult.noRemote));
      expect(ConflictResult.values, contains(ConflictResult.offline));
      expect(ConflictResult.values, contains(ConflictResult.error));
    });

    test('each value has a distinct index', () {
      final indices = ConflictResult.values.map((e) => e.index).toSet();
      expect(indices.length, ConflictResult.values.length);
    });
  });

  group('ConflictChoice', () {
    test('has all expected values', () {
      expect(ConflictChoice.values.length, 3);
      expect(ConflictChoice.values, contains(ConflictChoice.overrideLocal));
      expect(ConflictChoice.values, contains(ConflictChoice.keepLocal));
      expect(ConflictChoice.values, contains(ConflictChoice.cancel));
    });

    test('each value has a distinct index', () {
      final indices = ConflictChoice.values.map((e) => e.index).toSet();
      expect(indices.length, ConflictChoice.values.length);
    });
  });

  group('BackupException', () {
    test('creates exception with message only', () {
      final exception = BackupException('Something went wrong');

      expect(exception.message, 'Something went wrong');
      expect(exception.code, isNull);
    });

    test('creates exception with message and code', () {
      final exception = BackupException('Network error', code: 'network_error');

      expect(exception.message, 'Network error');
      expect(exception.code, 'network_error');
    });

    test('implements Exception interface', () {
      final exception = BackupException('test');

      expect(exception, isA<Exception>());
    });

    test('supports various error codes', () {
      final codes = ['network_error', 'credential_error', 's3_error'];
      for (final code in codes) {
        final exception = BackupException('Error', code: code);
        expect(exception.code, code);
      }
    });

    test('can be thrown and caught', () {
      expect(
        () => throw BackupException('Upload failed', code: 's3_error'),
        throwsA(isA<BackupException>()),
      );
    });

    test('caught exception preserves message and code', () {
      try {
        throw BackupException('Credential issue', code: 'credential_error');
      } on BackupException catch (e) {
        expect(e.message, 'Credential issue');
        expect(e.code, 'credential_error');
      }
    });
  });
}
