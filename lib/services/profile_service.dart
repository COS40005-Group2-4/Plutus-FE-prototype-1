import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/profile_model.dart';
import 'interfaces/i_database_service.dart';
import 'interfaces/i_profile_service.dart';
import '../di/service_locator.dart';

class ProfileService implements IProfileService {
  final IDatabaseService _db;

  ProfileService({IDatabaseService? db}) : _db = db ?? sl<IDatabaseService>();

  @override
  Future<Profile> createProfile({
    required int userId,
    String? avatarPath,
    String? dateOfBirth,
    String? position,
    String? placeOfEmployment,
    bool showName = true,
    bool showEmail = true,
    bool showDateOfBirth = false,
    bool showPosition = false,
    bool showPlaceOfEmployment = false,
  }) async {
    try {
      final now = DateTime.now();
      final profile = Profile(
        userId: userId,
        avatarPath: avatarPath,
        dateOfBirth: dateOfBirth,
        position: position,
        placeOfEmployment: placeOfEmployment,
        showName: showName,
        showEmail: showEmail,
        showDateOfBirth: showDateOfBirth,
        showPosition: showPosition,
        showPlaceOfEmployment: showPlaceOfEmployment,
        createdAt: now,
        updatedAt: now,
      );

      await _db.createProfile(profile);
      return profile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating profile: $e');
      }
      rethrow;
    }
  }

  @override
  Future<Profile?> getProfileByUserId(int userId) async {
    try {
      final profileMap = await _db.getProfileByUserId(userId);
      return profileMap != null ? Profile.fromMap(profileMap) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting profile: $e');
      }
      return null;
    }
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    try {
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );
      await _db.updateProfile(updatedProfile);
      return updatedProfile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating profile: $e');
      }
      rethrow;
    }
  }

  @override
  Future<String> saveAvatarImage(File imageFile, int userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');

      if (!avatarDir.existsSync()) {
        avatarDir.createSync(recursive: true);
      }

      final fileName = 'avatar_$userId.jpg';
      final savedPath = '${avatarDir.path}/$fileName';

      final savedFile = await imageFile.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving avatar: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteAvatarImage(String avatarPath) async {
    try {
      final file = File(avatarPath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting avatar: $e');
      }
    }
  }

  @override
  Future<void> deleteProfile(int userId) async {
    try {
      // Get profile to delete avatar
      final profile = await getProfileByUserId(userId);
      if (profile?.avatarPath != null) {
        await deleteAvatarImage(profile!.avatarPath!);
      }

      await _db.deleteProfile(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting profile: $e');
      }
      rethrow;
    }
  }
}
