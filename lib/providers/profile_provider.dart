import 'dart:io';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/interfaces/i_profile_service.dart';
import '../di/service_locator.dart';

/// Profile state enum
enum ProfileState { initial, loading, loaded, error, editing }

/// Profile Provider for managing profile state
class ProfileProvider extends ChangeNotifier {
  final IProfileService _profileService;

  ProfileProvider({IProfileService? profileService})
      : _profileService = profileService ?? sl<IProfileService>();

  Profile? _profile;
  ProfileState _state = ProfileState.initial;
  String _errorMessage = '';
  bool _isEditing = false;

  // Getters
  Profile? get profile => _profile;
  ProfileState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isEditing => _isEditing;

  /// Load user profile
  Future<void> loadProfile(int userId) async {
    try {
      _state = ProfileState.loading;
      notifyListeners();

      Profile? existingProfile = await _profileService.getProfileByUserId(userId);

      // Create default profile if it doesn't exist
      existingProfile ??= await _profileService.createProfile(
        userId: userId,
        showName: true,
        showEmail: true,
      );

      _profile = existingProfile;
      _state = ProfileState.loaded;
      _errorMessage = '';
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
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
    if (_profile == null) return;

    try {
      _state = ProfileState.loading;
      notifyListeners();

      final updatedProfile = _profile!.copyWith(
        dateOfBirth: dateOfBirth ?? _profile!.dateOfBirth,
        position: position ?? _profile!.position,
        placeOfEmployment: placeOfEmployment ?? _profile!.placeOfEmployment,
        showName: showName ?? _profile!.showName,
        showEmail: showEmail ?? _profile!.showEmail,
        showDateOfBirth: showDateOfBirth ?? _profile!.showDateOfBirth,
        showPosition: showPosition ?? _profile!.showPosition,
        showPlaceOfEmployment:
            showPlaceOfEmployment ?? _profile!.showPlaceOfEmployment,
      );

      _profile = await _profileService.updateProfile(updatedProfile);
      _state = ProfileState.loaded;
      _errorMessage = '';
      _isEditing = false;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Update avatar
  Future<void> updateAvatar(File imageFile) async {
    if (_profile == null) return;

    try {
      _state = ProfileState.loading;
      notifyListeners();

      // Delete old avatar if exists
      if (_profile!.avatarPath != null) {
        await _profileService.deleteAvatarImage(_profile!.avatarPath!);
      }

      // Save new avatar
      final savedPath = await _profileService.saveAvatarImage(
        imageFile,
        _profile!.userId,
      );

      // Update profile with new avatar path
      final updatedProfile = _profile!.copyWith(
        avatarPath: savedPath,
      );

      _profile = await _profileService.updateProfile(updatedProfile);
      _state = ProfileState.loaded;
      _errorMessage = '';
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Toggle visibility of a field
  Future<void> toggleFieldVisibility(String fieldName) async {
    if (_profile == null) return;

    try {
      late final Profile updatedProfile;

      switch (fieldName) {
        case 'name':
          updatedProfile = _profile!.copyWith(showName: !_profile!.showName);
          break;
        case 'email':
          updatedProfile = _profile!.copyWith(showEmail: !_profile!.showEmail);
          break;
        case 'dateOfBirth':
          updatedProfile = _profile!.copyWith(
            showDateOfBirth: !_profile!.showDateOfBirth,
          );
          break;
        case 'position':
          updatedProfile = _profile!.copyWith(
            showPosition: !_profile!.showPosition,
          );
          break;
        case 'placeOfEmployment':
          updatedProfile = _profile!.copyWith(
            showPlaceOfEmployment: !_profile!.showPlaceOfEmployment,
          );
          break;
        default:
          return;
      }

      _profile = await _profileService.updateProfile(updatedProfile);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Set editing mode
  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }

  /// Reset to loaded state
  void resetState() {
    if (_state == ProfileState.error) {
      _state = ProfileState.loaded;
      _errorMessage = '';
      notifyListeners();
    }
  }
}
