import 'dart:io';
import '../../models/profile_model.dart';

abstract class IProfileService {
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
  });
  Future<Profile?> getProfileByUserId(int userId);
  Future<Profile> updateProfile(Profile profile);
  Future<String> saveAvatarImage(File imageFile, int userId);
  Future<void> deleteAvatarImage(String avatarPath);
  Future<void> deleteProfile(int userId);
}
