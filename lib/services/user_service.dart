import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class UserService {
  final DatabaseService _db = DatabaseService();
  
  Future<User> createLocalUser({
    required String username,
    required String displayName,
    bool isGuest = false,
  }) async {
    try {
      // Check if username already exists
      final existing = await _db.getUserByUsername(username);
      if (existing != null) {
        throw Exception('Username already exists');
      }
      
      final userId = await _db.createUser(
        username: username,
        displayName: displayName,
        isGuest: isGuest,
      );
      
      final userMap = await _db.getUserById(userId);
      if (userMap == null) {
        throw Exception('Failed to create user');
      }
      
      return User.fromMap(userMap);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating local user: $e');
      }
      rethrow;
    }
  }
  
  Future<User> createOAuthUser({
    required String username,
    required String displayName,
    required String email,
    required String oauthProvider,
    required String oauthId,
  }) async {
    try {
      // Check if OAuth user already exists
      final existing = await _db.getUserByOAuth(oauthProvider, oauthId);
      if (existing != null) {
        return User.fromMap(existing);
      }
      
      final userId = await _db.createUser(
        username: username,
        displayName: displayName,
        email: email,
        oauthProvider: oauthProvider,
        oauthId: oauthId,
        isGuest: false,
      );
      
      final userMap = await _db.getUserById(userId);
      if (userMap == null) {
        throw Exception('Failed to create OAuth user');
      }
      
      return User.fromMap(userMap);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating OAuth user: $e');
      }
      rethrow;
    }
  }
  
  Future<User?> getUserById(int userId) async {
    try {
      final userMap = await _db.getUserById(userId);
      return userMap != null ? User.fromMap(userMap) : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by ID: $e');
      }
      return null;
    }
  }
  
  Future<User?> getUserByUsername(String username) async {
    try {
      final userMap = await _db.getUserByUsername(username);
      return userMap != null ? User.fromMap(userMap) : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by username: $e');
      }
      return null;
    }
  }
  
  Future<User?> getUserByOAuth(String provider, String oauthId) async {
    try {
      final userMap = await _db.getUserByOAuth(provider, oauthId);
      return userMap != null ? User.fromMap(userMap) : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by OAuth: $e');
      }
      return null;
    }
  }
  
  Future<List<User>> getAllUsers() async {
    try {
      final userMaps = await _db.getAllUsers();
      return userMaps.map((map) => User.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all users: $e');
      }
      return [];
    }
  }
  
  Future<void> updateLastLogin(int userId) async {
    try {
      await _db.updateUserLastLogin(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last login: $e');
      }
    }
  }
  
  Future<void> linkOAuthToUser({
    required int userId,
    required String provider,
    required String oauthId,
    required String email,
  }) async {
    try {
      await _db.linkOAuthToUser(userId, provider, oauthId, email);
    } catch (e) {
      if (kDebugMode) {
        print('Error linking OAuth to user: $e');
      }
      rethrow;
    }
  }
  
  Future<void> unlinkOAuthFromUser(int userId) async {
    try {
      await _db.unlinkOAuthFromUser(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error unlinking OAuth from user: $e');
      }
      rethrow;
    }
  }
  
  Future<void> clearUserData(int userId) async {
    try {
      await _db.clearUserData(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user data: $e');
      }
      rethrow;
    }
  }
}
