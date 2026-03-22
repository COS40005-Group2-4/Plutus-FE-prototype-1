import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/profile_model.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('Profile', () {
    group('fromMap', () {
      test('creates profile with all fields', () {
        final now = DateTime(2024, 1, 1);
        final map = {
          'user_id': 1,
          'avatar_path': '/path/to/avatar.png',
          'date_of_birth': '1990-01-15',
          'position': 'Engineer',
          'place_of_employment': 'Acme Corp',
          'show_name': 1,
          'show_email': 1,
          'show_date_of_birth': 1,
          'show_position': 1,
          'show_place_of_employment': 1,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
        };

        final profile = Profile.fromMap(map);

        expect(profile.userId, 1);
        expect(profile.avatarPath, '/path/to/avatar.png');
        expect(profile.dateOfBirth, '1990-01-15');
        expect(profile.position, 'Engineer');
        expect(profile.placeOfEmployment, 'Acme Corp');
        expect(profile.showName, true);
        expect(profile.showEmail, true);
        expect(profile.showDateOfBirth, true);
        expect(profile.showPosition, true);
        expect(profile.showPlaceOfEmployment, true);
        expect(profile.createdAt, now);
        expect(profile.updatedAt, now);
      });

      test('handles null optional fields', () {
        final now = DateTime(2024, 1, 1);
        final map = {
          'user_id': 1,
          'avatar_path': null,
          'date_of_birth': null,
          'position': null,
          'place_of_employment': null,
          'show_name': 0,
          'show_email': 0,
          'show_date_of_birth': 0,
          'show_position': 0,
          'show_place_of_employment': 0,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
        };

        final profile = Profile.fromMap(map);

        expect(profile.avatarPath, isNull);
        expect(profile.dateOfBirth, isNull);
        expect(profile.position, isNull);
        expect(profile.placeOfEmployment, isNull);
      });

      test('parses boolean flags from integers correctly', () {
        final now = DateTime(2024, 1, 1);
        final map = {
          'user_id': 1,
          'avatar_path': null,
          'date_of_birth': null,
          'position': null,
          'place_of_employment': null,
          'show_name': 0,
          'show_email': 1,
          'show_date_of_birth': 0,
          'show_position': 1,
          'show_place_of_employment': 0,
          'created_at': now.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
        };

        final profile = Profile.fromMap(map);

        expect(profile.showName, false);
        expect(profile.showEmail, true);
        expect(profile.showDateOfBirth, false);
        expect(profile.showPosition, true);
        expect(profile.showPlaceOfEmployment, false);
      });

      test('parses timestamps from milliseconds', () {
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 6, 15);
        final map = {
          'user_id': 1,
          'avatar_path': null,
          'date_of_birth': null,
          'position': null,
          'place_of_employment': null,
          'show_name': 1,
          'show_email': 1,
          'show_date_of_birth': 0,
          'show_position': 0,
          'show_place_of_employment': 0,
          'created_at': created.millisecondsSinceEpoch,
          'updated_at': updated.millisecondsSinceEpoch,
        };

        final profile = Profile.fromMap(map);

        expect(profile.createdAt, created);
        expect(profile.updatedAt, updated);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final profile = createTestProfile(
          avatarPath: '/avatar.png',
          dateOfBirth: '1990-05-20',
          position: 'Manager',
          placeOfEmployment: 'Corp Inc',
        );
        final map = profile.toMap();

        expect(map['user_id'], 1);
        expect(map['avatar_path'], '/avatar.png');
        expect(map['date_of_birth'], '1990-05-20');
        expect(map['position'], 'Manager');
        expect(map['place_of_employment'], 'Corp Inc');
      });

      test('serializes booleans as integers', () {
        final profile = createTestProfile(
          showName: true,
          showEmail: false,
          showDateOfBirth: true,
          showPosition: false,
          showPlaceOfEmployment: true,
        );
        final map = profile.toMap();

        expect(map['show_name'], 1);
        expect(map['show_email'], 0);
        expect(map['show_date_of_birth'], 1);
        expect(map['show_position'], 0);
        expect(map['show_place_of_employment'], 1);
      });

      test('serializes timestamps as milliseconds', () {
        final date = DateTime(2024, 3, 15);
        final profile = createTestProfile(createdAt: date, updatedAt: date);
        final map = profile.toMap();

        expect(map['created_at'], date.millisecondsSinceEpoch);
        expect(map['updated_at'], date.millisecondsSinceEpoch);
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all data through serialization cycle', () {
        final original = createTestProfile(
          avatarPath: '/img/avatar.jpg',
          dateOfBirth: '1995-12-25',
          position: 'CTO',
          placeOfEmployment: 'Startup LLC',
          showName: true,
          showEmail: false,
          showDateOfBirth: true,
          showPosition: true,
          showPlaceOfEmployment: false,
        );
        final restored = Profile.fromMap(original.toMap());

        expect(restored, original);
      });

      test('preserves profile with all null optionals', () {
        final original = createTestProfile();
        final restored = Profile.fromMap(original.toMap());

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no overrides given', () {
        final profile = createTestProfile();
        final copy = profile.copyWith();

        expect(copy, profile);
      });

      test('overrides only specified fields', () {
        final profile = createTestProfile();
        final copy = profile.copyWith(
          position: 'Senior Engineer',
          showPosition: true,
        );

        expect(copy.position, 'Senior Engineer');
        expect(copy.showPosition, true);
        expect(copy.userId, profile.userId);
        expect(copy.showName, profile.showName);
        expect(copy.showEmail, profile.showEmail);
      });

      test('can update avatar path', () {
        final profile = createTestProfile();
        final copy = profile.copyWith(avatarPath: '/new/avatar.png');

        expect(copy.avatarPath, '/new/avatar.png');
      });

      test('can update updatedAt independently', () {
        final profile = createTestProfile();
        final newDate = DateTime(2024, 12, 1);
        final copy = profile.copyWith(updatedAt: newDate);

        expect(copy.updatedAt, newDate);
        expect(copy.createdAt, profile.createdAt);
      });
    });

    group('Equatable', () {
      test('identical profiles are equal', () {
        final p1 = createTestProfile();
        final p2 = createTestProfile();

        expect(p1, p2);
        expect(p1.hashCode, p2.hashCode);
      });

      test('profiles with different userIds are not equal', () {
        final p1 = createTestProfile(userId: 1);
        final p2 = createTestProfile(userId: 2);

        expect(p1, isNot(p2));
      });

      test('profiles with different visibility settings are not equal', () {
        final p1 = createTestProfile(showName: true);
        final p2 = createTestProfile(showName: false);

        expect(p1, isNot(p2));
      });

      test('profiles with different positions are not equal', () {
        final p1 = createTestProfile(position: 'Engineer');
        final p2 = createTestProfile(position: 'Manager');

        expect(p1, isNot(p2));
      });
    });

    group('default values', () {
      test('showName and showEmail default to true', () {
        final profile = createTestProfile();

        expect(profile.showName, true);
        expect(profile.showEmail, true);
      });

      test('other visibility flags default to false', () {
        final profile = createTestProfile();

        expect(profile.showDateOfBirth, false);
        expect(profile.showPosition, false);
        expect(profile.showPlaceOfEmployment, false);
      });
    });
  });
}
