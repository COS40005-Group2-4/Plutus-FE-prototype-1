import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/providers/profile_provider.dart';
import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIProfileService mockProfileService;
  late ProfileProvider provider;

  setUp(() {
    mockProfileService = MockIProfileService();
    provider = ProfileProvider(profileService: mockProfileService);
  });

  group('ProfileProvider', () {
    test('initial state is correct', () {
      expect(provider.profile, isNull);
      expect(provider.state, ProfileState.initial);
      expect(provider.errorMessage, '');
      expect(provider.isEditing, false);
    });

    test('loadProfile loads existing profile', () async {
      final testProfile = createTestProfile(userId: 1, position: 'Developer');
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);

      await provider.loadProfile(1);

      expect(provider.profile, testProfile);
      expect(provider.state, ProfileState.loaded);
      expect(provider.errorMessage, '');
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

      await provider.loadProfile(1);

      expect(provider.profile, defaultProfile);
      expect(provider.state, ProfileState.loaded);
      verify(mockProfileService.createProfile(
        userId: 1,
        showName: true,
        showEmail: true,
      )).called(1);
    });

    test('loadProfile handles errors', () async {
      when(mockProfileService.getProfileByUserId(1))
          .thenThrow(Exception('DB error'));

      await provider.loadProfile(1);

      expect(provider.state, ProfileState.error);
      expect(provider.errorMessage, contains('DB error'));
    });

    test('updateProfile updates fields', () async {
      // First load a profile
      final testProfile = createTestProfile(userId: 1);
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);
      await provider.loadProfile(1);

      // Set up the update mock
      final updatedProfile = testProfile.copyWith(position: 'Senior Dev');
      when(mockProfileService.updateProfile(any))
          .thenAnswer((_) async => updatedProfile);

      await provider.updateProfile(position: 'Senior Dev');

      expect(provider.profile!.position, 'Senior Dev');
      expect(provider.state, ProfileState.loaded);
      expect(provider.isEditing, false);
    });

    test('updateProfile does nothing when profile is null', () async {
      await provider.updateProfile(position: 'Dev');
      verifyNever(mockProfileService.updateProfile(any));
    });

    test('toggleFieldVisibility toggles showName', () async {
      final testProfile = createTestProfile(userId: 1, showName: true);
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);
      await provider.loadProfile(1);

      final toggled = testProfile.copyWith(showName: false);
      when(mockProfileService.updateProfile(any))
          .thenAnswer((_) async => toggled);

      await provider.toggleFieldVisibility('name');

      expect(provider.profile!.showName, false);
    });

    test('toggleFieldVisibility ignores unknown field', () async {
      final testProfile = createTestProfile(userId: 1);
      when(mockProfileService.getProfileByUserId(1))
          .thenAnswer((_) async => testProfile);
      await provider.loadProfile(1);

      await provider.toggleFieldVisibility('unknownField');
      verifyNever(mockProfileService.updateProfile(any));
    });

    test('setEditing updates isEditing', () {
      expect(provider.isEditing, false);
      provider.setEditing(true);
      expect(provider.isEditing, true);
      provider.setEditing(false);
      expect(provider.isEditing, false);
    });

    test('resetState resets error to loaded', () async {
      // Force error state
      when(mockProfileService.getProfileByUserId(1))
          .thenThrow(Exception('fail'));
      await provider.loadProfile(1);
      expect(provider.state, ProfileState.error);

      provider.resetState();
      expect(provider.state, ProfileState.loaded);
      expect(provider.errorMessage, '');
    });

    test('resetState does nothing if not in error state', () {
      expect(provider.state, ProfileState.initial);
      provider.resetState();
      expect(provider.state, ProfileState.initial);
    });
  });
}
