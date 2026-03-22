import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/services/user_service.dart';

import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIDatabaseService mockDb;
  late UserService service;

  setUp(() {
    mockDb = MockIDatabaseService();
    service = UserService(db: mockDb);
  });

  group('createLocalUser', () {
    test('creates user when username does not exist', () async {
      when(mockDb.getUserByUsername('newuser'))
          .thenAnswer((_) async => null);
      when(mockDb.createUser(
        username: 'newuser',
        displayName: 'New User',
        isGuest: false,
      )).thenAnswer((_) async => 1);
      when(mockDb.getUserById(1))
          .thenAnswer((_) async => createTestUserMap(
                id: 1,
                username: 'newuser',
                displayName: 'New User',
              ));

      final user = await service.createLocalUser(
        username: 'newuser',
        displayName: 'New User',
      );

      expect(user.username, 'newuser');
      expect(user.displayName, 'New User');
      verify(mockDb.getUserByUsername('newuser')).called(1);
      verify(mockDb.createUser(
        username: 'newuser',
        displayName: 'New User',
        isGuest: false,
      )).called(1);
    });

    test('throws when username already exists', () async {
      when(mockDb.getUserByUsername('existing'))
          .thenAnswer((_) async => createTestUserMap(username: 'existing'));

      expect(
        () => service.createLocalUser(
          username: 'existing',
          displayName: 'Existing User',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('creates guest user with isGuest flag', () async {
      when(mockDb.getUserByUsername('guest'))
          .thenAnswer((_) async => null);
      when(mockDb.createUser(
        username: 'guest',
        displayName: 'Guest',
        isGuest: true,
      )).thenAnswer((_) async => 2);
      when(mockDb.getUserById(2))
          .thenAnswer((_) async => createTestUserMap(
                id: 2,
                username: 'guest',
                displayName: 'Guest',
                isGuest: true,
              ));

      final user = await service.createLocalUser(
        username: 'guest',
        displayName: 'Guest',
        isGuest: true,
      );

      expect(user.isGuest, true);
    });

    test('throws when getUserById returns null after creation', () async {
      when(mockDb.getUserByUsername('newuser'))
          .thenAnswer((_) async => null);
      when(mockDb.createUser(
        username: 'newuser',
        displayName: 'New User',
        isGuest: false,
      )).thenAnswer((_) async => 99);
      when(mockDb.getUserById(99)).thenAnswer((_) async => null);

      expect(
        () => service.createLocalUser(
          username: 'newuser',
          displayName: 'New User',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('createOAuthUser', () {
    test('returns existing user when OAuth user already exists', () async {
      final existingMap = createTestUserMap(
        id: 5,
        username: 'oauth_user',
        oauthProvider: 'google',
        oauthId: 'goog_123',
      );
      when(mockDb.getUserByOAuth('google', 'goog_123'))
          .thenAnswer((_) async => existingMap);

      final user = await service.createOAuthUser(
        username: 'oauth_user',
        displayName: 'OAuth User',
        email: 'oauth@test.com',
        oauthProvider: 'google',
        oauthId: 'goog_123',
      );

      expect(user.id, 5);
      verifyNever(mockDb.createUser(
        username: anyNamed('username'),
        displayName: anyNamed('displayName'),
        email: anyNamed('email'),
        oauthProvider: anyNamed('oauthProvider'),
        oauthId: anyNamed('oauthId'),
        isGuest: anyNamed('isGuest'),
      ));
    });

    test('creates new user when OAuth user does not exist', () async {
      when(mockDb.getUserByOAuth('google', 'goog_new'))
          .thenAnswer((_) async => null);
      when(mockDb.createUser(
        username: 'new_oauth',
        displayName: 'New OAuth',
        email: 'new@test.com',
        oauthProvider: 'google',
        oauthId: 'goog_new',
        isGuest: false,
      )).thenAnswer((_) async => 10);
      when(mockDb.getUserById(10))
          .thenAnswer((_) async => createTestUserMap(
                id: 10,
                username: 'new_oauth',
                displayName: 'New OAuth',
                email: 'new@test.com',
                oauthProvider: 'google',
                oauthId: 'goog_new',
              ));

      final user = await service.createOAuthUser(
        username: 'new_oauth',
        displayName: 'New OAuth',
        email: 'new@test.com',
        oauthProvider: 'google',
        oauthId: 'goog_new',
      );

      expect(user.id, 10);
      expect(user.username, 'new_oauth');
    });
  });

  group('getUserById', () {
    test('returns user when found', () async {
      when(mockDb.getUserById(1))
          .thenAnswer((_) async => createTestUserMap());

      final user = await service.getUserById(1);

      expect(user, isNotNull);
      expect(user!.id, 1);
      expect(user.username, 'testuser');
      verify(mockDb.getUserById(1)).called(1);
    });

    test('returns null when user not found', () async {
      when(mockDb.getUserById(999))
          .thenAnswer((_) async => null);

      final user = await service.getUserById(999);

      expect(user, isNull);
    });

    test('returns null on database error', () async {
      when(mockDb.getUserById(1))
          .thenThrow(Exception('DB error'));

      final user = await service.getUserById(1);

      expect(user, isNull);
    });
  });

  group('getUserByUsername', () {
    test('returns user when found', () async {
      when(mockDb.getUserByUsername('testuser'))
          .thenAnswer((_) async => createTestUserMap());

      final user = await service.getUserByUsername('testuser');

      expect(user, isNotNull);
      expect(user!.username, 'testuser');
    });

    test('returns null when not found', () async {
      when(mockDb.getUserByUsername('nonexistent'))
          .thenAnswer((_) async => null);

      final user = await service.getUserByUsername('nonexistent');

      expect(user, isNull);
    });
  });

  group('getUserByOAuth', () {
    test('returns user when found', () async {
      when(mockDb.getUserByOAuth('google', 'abc'))
          .thenAnswer((_) async => createTestUserMap(
                oauthProvider: 'google',
                oauthId: 'abc',
              ));

      final user = await service.getUserByOAuth('google', 'abc');

      expect(user, isNotNull);
      expect(user!.oauthProvider, 'google');
    });

    test('returns null when not found', () async {
      when(mockDb.getUserByOAuth('google', 'unknown'))
          .thenAnswer((_) async => null);

      final user = await service.getUserByOAuth('google', 'unknown');

      expect(user, isNull);
    });
  });

  group('getAllUsers', () {
    test('returns list of users', () async {
      when(mockDb.getAllUsers()).thenAnswer((_) async => [
            createTestUserMap(id: 1, username: 'user1'),
            createTestUserMap(id: 2, username: 'user2'),
          ]);

      final users = await service.getAllUsers();

      expect(users.length, 2);
      expect(users[0].username, 'user1');
      expect(users[1].username, 'user2');
    });

    test('returns empty list when no users', () async {
      when(mockDb.getAllUsers()).thenAnswer((_) async => []);

      final users = await service.getAllUsers();

      expect(users, isEmpty);
    });

    test('returns empty list on error', () async {
      when(mockDb.getAllUsers()).thenThrow(Exception('DB error'));

      final users = await service.getAllUsers();

      expect(users, isEmpty);
    });
  });

  group('updateLastLogin', () {
    test('calls db updateUserLastLogin', () async {
      when(mockDb.updateUserLastLogin(1))
          .thenAnswer((_) async {});

      await service.updateLastLogin(1);

      verify(mockDb.updateUserLastLogin(1)).called(1);
    });
  });

  group('linkOAuthToUser', () {
    test('delegates to db linkOAuthToUser', () async {
      when(mockDb.linkOAuthToUser(1, 'google', 'oauthid', 'email@test.com'))
          .thenAnswer((_) async {});

      await service.linkOAuthToUser(
        userId: 1,
        provider: 'google',
        oauthId: 'oauthid',
        email: 'email@test.com',
      );

      verify(mockDb.linkOAuthToUser(1, 'google', 'oauthid', 'email@test.com'))
          .called(1);
    });

    test('rethrows on error', () async {
      when(mockDb.linkOAuthToUser(1, 'google', 'oauthid', 'email@test.com'))
          .thenThrow(Exception('Link failed'));

      expect(
        () => service.linkOAuthToUser(
          userId: 1,
          provider: 'google',
          oauthId: 'oauthid',
          email: 'email@test.com',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('clearUserData', () {
    test('delegates to db clearUserData', () async {
      when(mockDb.clearUserData(1)).thenAnswer((_) async {});

      await service.clearUserData(1);

      verify(mockDb.clearUserData(1)).called(1);
    });

    test('rethrows on error', () async {
      when(mockDb.clearUserData(1)).thenThrow(Exception('Clear failed'));

      expect(
        () => service.clearUserData(1),
        throwsA(isA<Exception>()),
      );
    });
  });
}
