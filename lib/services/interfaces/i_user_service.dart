import '../../models/user_model.dart';

abstract class IUserService {
  Future<User> createLocalUser({
    required String username,
    required String displayName,
    bool isGuest = false,
  });
  Future<User> createOAuthUser({
    required String username,
    required String displayName,
    required String email,
    required String oauthProvider,
    required String oauthId,
  });
  Future<User?> getUserById(int userId);
  Future<User?> getUserByUsername(String username);
  Future<User?> getUserByOAuth(String provider, String oauthId);
  Future<List<User>> getAllUsers();
  Future<void> updateLastLogin(int userId);
  Future<void> linkOAuthToUser({
    required int userId,
    required String provider,
    required String oauthId,
    required String email,
  });
  Future<void> unlinkOAuthFromUser(int userId);
  Future<void> clearUserData(int userId);
}
