import 'package:flutter/material.dart';

abstract class IGoogleAuthService {
  Stream<dynamic> get authenticationState;
  Future<bool> isAuthenticated();
  Future<bool> signIn();
  Future<void> signOut();
  Future<Map<String, dynamic>> getSessionInfo();
  Future<Map<String, dynamic>> getUserInfo();
  Widget? getSignInButton();
}
