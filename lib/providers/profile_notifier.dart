import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../services/interfaces/i_profile_service.dart';
import '../di/service_locator.dart';
import 'auth_notifier.dart';

// ---------------------------------------------------------------------------
// ProfileStatus enum
// ---------------------------------------------------------------------------

enum ProfileStatus { initial, loading, loaded, error, editing }

// ---------------------------------------------------------------------------
// ProfileState — immutable value type
// ---------------------------------------------------------------------------

class ProfileState {
  final Profile? profile;
  final ProfileStatus status;
  final String errorMessage;
  final bool isEditing;

  const ProfileState({
    this.profile,
    this.status = ProfileStatus.initial,
    this.errorMessage = '',
    this.isEditing = false,
  });

  ProfileState copyWith({
    Profile? profile,
    ProfileStatus? status,
    String? errorMessage,
    bool? isEditing,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

// ---------------------------------------------------------------------------
// ProfileNotifier
// ---------------------------------------------------------------------------

class ProfileNotifier extends Notifier<ProfileState> {
  late IProfileService _profileService;

  @override
  ProfileState build() {
    _profileService = sl<IProfileService>();

    // Watch auth state — load profile when user authenticates.
    final AuthState authState = ref.watch(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      Future.microtask(() => loadProfile(authState.user.id));
    }

    return const ProfileState();
  }

  // -------------------------------------------------------------------------
  // Public methods
  // -------------------------------------------------------------------------

  /// Load user profile
  Future<void> loadProfile(int userId) async {
    state = state.copyWith(status: ProfileStatus.loading);

    try {
      Profile? existingProfile = await _profileService.getProfileByUserId(userId);

      // Create default profile if it doesn't exist
      existingProfile ??= await _profileService.createProfile(
        userId: userId,
        showName: true,
        showEmail: true,
      );

      state = state.copyWith(
        profile: existingProfile,
        status: ProfileStatus.loaded,
        errorMessage: '',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update profile information
  Future<void> updateProfile({
    String? dateOfBirth,
    String? position,
    String? placeOfEmployment,
    bool? showName,
    bool? showEmail,
    bool? showDateOfBirth,
    bool? showPosition,
    bool? showPlaceOfEmployment,
  }) async {
    if (state.profile == null) return;

    state = state.copyWith(status: ProfileStatus.loading);

    try {
      final Profile updatedProfile = state.profile!.copyWith(
        dateOfBirth: dateOfBirth ?? state.profile!.dateOfBirth,
        position: position ?? state.profile!.position,
        placeOfEmployment: placeOfEmployment ?? state.profile!.placeOfEmployment,
        showName: showName ?? state.profile!.showName,
        showEmail: showEmail ?? state.profile!.showEmail,
        showDateOfBirth: showDateOfBirth ?? state.profile!.showDateOfBirth,
        showPosition: showPosition ?? state.profile!.showPosition,
        showPlaceOfEmployment: showPlaceOfEmployment ?? state.profile!.showPlaceOfEmployment,
      );

      final Profile saved = await _profileService.updateProfile(updatedProfile);
      state = state.copyWith(
        profile: saved,
        status: ProfileStatus.loaded,
        errorMessage: '',
        isEditing: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update avatar
  Future<void> updateAvatar(File imageFile) async {
    if (state.profile == null) return;

    state = state.copyWith(status: ProfileStatus.loading);

    try {
      // Delete old avatar if exists
      if (state.profile!.avatarPath != null) {
        await _profileService.deleteAvatarImage(state.profile!.avatarPath!);
      }

      // Save new avatar
      final String savedPath = await _profileService.saveAvatarImage(
        imageFile,
        state.profile!.userId,
      );

      // Update profile with new avatar path
      final Profile updatedProfile = state.profile!.copyWith(
        avatarPath: savedPath,
      );

      final Profile saved = await _profileService.updateProfile(updatedProfile);
      state = state.copyWith(
        profile: saved,
        status: ProfileStatus.loaded,
        errorMessage: '',
      );
    } catch (e) {
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Toggle visibility of a field
  Future<void> toggleFieldVisibility(String fieldName) async {
    if (state.profile == null) return;

    try {
      late final Profile updatedProfile;

      switch (fieldName) {
        case 'name':
          updatedProfile = state.profile!.copyWith(showName: !state.profile!.showName);
          break;
        case 'email':
          updatedProfile = state.profile!.copyWith(showEmail: !state.profile!.showEmail);
          break;
        case 'dateOfBirth':
          updatedProfile =
              state.profile!.copyWith(showDateOfBirth: !state.profile!.showDateOfBirth);
          break;
        case 'position':
          updatedProfile =
              state.profile!.copyWith(showPosition: !state.profile!.showPosition);
          break;
        case 'placeOfEmployment':
          updatedProfile = state.profile!.copyWith(
            showPlaceOfEmployment: !state.profile!.showPlaceOfEmployment,
          );
          break;
        default:
          return;
      }

      final Profile saved = await _profileService.updateProfile(updatedProfile);
      state = state.copyWith(profile: saved);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Set editing mode
  void setEditing(bool value) {
    state = state.copyWith(isEditing: value);
  }

  /// Reset to loaded state (clear error)
  void resetState() {
    if (state.status == ProfileStatus.error) {
      state = state.copyWith(
        status: ProfileStatus.loaded,
        errorMessage: '',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider definition
// ---------------------------------------------------------------------------

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
