import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/user_model.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('User', () {
    group('fromMap', () {
      test('creates user with all fields', () {
        final map = createTestUserMap();
        final user = User.fromMap(map);

        expect(user.id, 1);
        expect(user.username, 'testuser');
        expect(user.displayName, 'Test User');
        expect(user.email, 'test@example.com');
        expect(user.oauthProvider, isNull);
        expect(user.oauthId, isNull);
        expect(user.isGuest, false);
        expect(user.isActive, true);
      });

      test('creates user with null optional fields', () {
        final map = createTestUserMap(email: null, oauthProvider: null, oauthId: null);
        final user = User.fromMap(map);

        expect(user.email, isNull);
        expect(user.oauthProvider, isNull);
        expect(user.oauthId, isNull);
      });

      test('parses guest user correctly', () {
        final map = createTestUserMap(isGuest: true);
        final user = User.fromMap(map);

        expect(user.isGuest, true);
      });

      test('parses OAuth user correctly', () {
        final map = createTestUserMap(
          oauthProvider: 'google',
          oauthId: 'google_123',
        );
        final user = User.fromMap(map);

        expect(user.oauthProvider, 'google');
        expect(user.oauthId, 'google_123');
      });

      test('parses timestamps from milliseconds', () {
        final expectedDate = DateTime(2024, 1, 1);
        final map = createTestUserMap();
        final user = User.fromMap(map);

        expect(user.createdAt, expectedDate);
        expect(user.lastLogin, expectedDate);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final user = createTestUser();
        final map = user.toMap();

        expect(map['id'], 1);
        expect(map['username'], 'testuser');
        expect(map['display_name'], 'Test User');
        expect(map['email'], 'test@example.com');
        expect(map['is_guest'], 0);
        expect(map['is_active'], 1);
      });

      test('serializes booleans as integers', () {
        final guestUser = createTestUser(isGuest: true, isActive: false);
        final map = guestUser.toMap();

        expect(map['is_guest'], 1);
        expect(map['is_active'], 0);
      });

      test('serializes timestamps as milliseconds', () {
        final date = DateTime(2024, 6, 15);
        final user = createTestUser(createdAt: date, lastLogin: date);
        final map = user.toMap();

        expect(map['created_at'], date.millisecondsSinceEpoch);
        expect(map['last_login'], date.millisecondsSinceEpoch);
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all data through serialization cycle', () {
        final original = createTestUser(
          oauthProvider: 'google',
          oauthId: 'oauth_abc',
        );
        final restored = User.fromMap(original.toMap());

        expect(restored, original);
      });

      test('preserves null optional fields through round-trip', () {
        final original = createTestUser(email: null);
        final restored = User.fromMap(original.toMap());

        expect(restored.email, isNull);
        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no overrides given', () {
        final user = createTestUser();
        final copy = user.copyWith();

        expect(copy, user);
      });

      test('overrides only specified fields', () {
        final user = createTestUser();
        final copy = user.copyWith(username: 'newuser', isActive: false);

        expect(copy.username, 'newuser');
        expect(copy.isActive, false);
        expect(copy.id, user.id);
        expect(copy.displayName, user.displayName);
        expect(copy.email, user.email);
      });

      test('can update lastLogin independently', () {
        final user = createTestUser();
        final newLogin = DateTime(2024, 6, 1);
        final copy = user.copyWith(lastLogin: newLogin);

        expect(copy.lastLogin, newLogin);
        expect(copy.createdAt, user.createdAt);
      });
    });

    group('Equatable', () {
      test('two users with same fields are equal', () {
        final user1 = createTestUser();
        final user2 = createTestUser();

        expect(user1, user2);
        expect(user1.hashCode, user2.hashCode);
      });

      test('two users with different ids are not equal', () {
        final user1 = createTestUser(id: 1);
        final user2 = createTestUser(id: 2);

        expect(user1, isNot(user2));
      });

      test('two users with different emails are not equal', () {
        final user1 = createTestUser(email: 'a@test.com');
        final user2 = createTestUser(email: 'b@test.com');

        expect(user1, isNot(user2));
      });
    });

    group('hasOAuth', () {
      test('returns true when both oauthProvider and oauthId are set', () {
        final user = createTestUser(oauthProvider: 'google', oauthId: 'id_123');

        expect(user.hasOAuth, true);
      });

      test('returns false when oauthProvider is null', () {
        final user = createTestUser(oauthId: 'id_123');

        expect(user.hasOAuth, false);
      });

      test('returns false when oauthId is null', () {
        final user = createTestUser(oauthProvider: 'google');

        expect(user.hasOAuth, false);
      });

      test('returns false when both are null', () {
        final user = createTestUser();

        expect(user.hasOAuth, false);
      });
    });
  });
}
