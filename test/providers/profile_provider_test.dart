import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/user_model.dart';
import 'package:plutus_fe_prototype/providers/auth_notifier.dart';
import 'package:plutus_fe_prototype/providers/profile_notifier.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_profile_service.dart';
import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

// ---------------------------------------------------------------------------
// Fake AuthNotifier — returns a fixed state
// ---------------------------------------------------------------------------

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

User _makeUser({int userId = 1}) {
  final now = DateTime(2024, 1, 1);
  return User(
    id: userId,
    username: 'testuser',
    displayName: 'Test User',
    email: 'test@example.com',
    isGuest: false,
    createdAt: now,
    lastLogin: now,
    isActive: true,
  );
}

void main() {
  late MockIProfileService mockProfileService;
  final GetIt sl = GetIt.instance;

  setUp(() async {
    mockProfileService = MockIProfileService();
    // Register mock in GetIt — reset first to avoid duplicate registration errors
    if (sl.isRegistered<IProfileService>()) {
      await sl.unregister<IProfileService>();
    }
    sl.registerSingleton<IProfileService>(mockProfileService);
  });

  tearDown(() async {
    if (sl.isRegistered<IProfileService>()) {
      await sl.unregister<IProfileService>();
    }
  });

  ProviderContainer makeContainer({AuthState? authState}) {
    return ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(authState ?? const AuthUnauthenticated()),
        ),
      ],
    );
  }

  group('ProfileNotifier', () {
    test('initial state is correct', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(profileNotifierProvider);
      expect(state.profile, isNull);
      expect(state.status, ProfileStatus.initial);
      expect(state.errorMessage, '');
      expect(state.isEditing, false);
    });

    test('loadProfile loads existing profile', () async {
      final testProfile = createTestProfile(userId: 1, position: 'Developer');
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(1);

      final state = container.read(profileNotifierProvider);
      expect(state.profile, testProfile);
      expect(state.status, ProfileStatus.loaded);
      expect(state.errorMessage, '');
      verify(mockProfileService.getProfileByUserId(1)).called(1);
    });

    test('loadProfile creates default when none exists', () async {
      final defaultProfile = createTestProfile(userId: 1);
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => null);
      when(mockProfileService.createProfile(
        userId: 1,
        showName: true,
        showEmail: true,
      )).thenAnswer((_) async => defaultProfile);

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(1);

      final state = container.read(profileNotifierProvider);
      expect(state.profile, defaultProfile);
      expect(state.status, ProfileStatus.loaded);
      verify(mockProfileService.createProfile(
        userId: 1,
        showName: true,
        showEmail: true,
      )).called(1);
    });

    test('loadProfile handles errors', () async {
      when(mockProfileService.getProfileByUserId(1))
          .thenThrow(Exception('DB error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(1);

      final state = container.read(profileNotifierProvider);
      expect(state.status, ProfileStatus.error);
      expect(state.errorMessage, contains('DB error'));
    });

    test('updateProfile updates fields', () async {
      // First load a profile
      final testProfile = createTestProfile(userId: 1);
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(1);

      // Set up the update mock
      final updatedProfile = testProfile.copyWith(position: 'Senior Dev');
      when(mockProfileService.updateProfile(any))
          .thenAnswer((_) async => updatedProfile);

      await notifier.updateProfile(position: 'Senior Dev');

      final state = container.read(profileNotifierProvider);
      expect(state.profile!.position, 'Senior Dev');
      expect(state.status, ProfileStatus.loaded);
      expect(state.isEditing, false);
    });

    test('updateProfile does nothing when profile is null', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.updateProfile(position: 'Dev');
      verifyNever(mockProfileService.updateProfile(any));
    });

    test('toggleFieldVisibility toggles showName', () async {
      final testProfile = createTestProfile(userId: 1, showName: true);
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(1);

      final toggled = testProfile.copyWith(showName: false);
      when(mockProfileService.updateProfile(any))
          .thenAnswer((_) async => toggled);

      await notifier.toggleFieldVisibility('name');

      final state = container.read(profileNotifierProvider);
      expect(state.profile!.showName, false);
    });

    test('toggleFieldVisibility ignores unknown field', () async {
      final testProfile = createTestProfile(userId: 1);
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(1);
      await notifier.toggleFieldVisibility('unknownField');
      verifyNever(mockProfileService.updateProfile(any));
    });

    test('setEditing updates isEditing', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      expect(container.read(profileNotifierProvider).isEditing, false);

      notifier.setEditing(true);
      expect(container.read(profileNotifierProvider).isEditing, true);

      notifier.setEditing(false);
      expect(container.read(profileNotifierProvider).isEditing, false);
    });

    test('resetState resets error to loaded', () async {
      when(mockProfileService.getProfileByUserId(1))
          .thenThrow(Exception('fail'));

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      await notifier.loadProfile(1);
      expect(container.read(profileNotifierProvider).status, ProfileStatus.error);

      notifier.resetState();
      final state = container.read(profileNotifierProvider);
      expect(state.status, ProfileStatus.loaded);
      expect(state.errorMessage, '');
    });

    test('resetState does nothing if not in error state', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(profileNotifierProvider.notifier);
      expect(container.read(profileNotifierProvider).status, ProfileStatus.initial);
      notifier.resetState();
      expect(container.read(profileNotifierProvider).status, ProfileStatus.initial);
    });

    test('auto-loads profile on auth change', () async {
      final testUser = _makeUser(userId: 42);
      final testProfile = createTestProfile(userId: 42);
      when(mockProfileService.getProfileByUserId(42))
          .thenAnswer((_) async => testProfile);

      final container = makeContainer(authState: AuthAuthenticated(testUser));
      addTearDown(container.dispose);

      // Read to trigger build, then wait for microtask
      container.read(profileNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(profileNotifierProvider);
      expect(state.profile, testProfile);
      expect(state.status, ProfileStatus.loaded);
    });
  });
}
