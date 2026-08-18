import 'dart:io';

import 'package:prince_academy/features/auth/data/models/app_user.dart';

abstract class AuthRepo {
  Future<String> signUp(String email, String password);

  Future<void> saveProfile({
    required String userId,
    required String fullName,
    required String phone,
  });

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  });

  Future<String> uploadAvatar(File file);

  Future<void> signIn(String email, String password);

  /// Native Google ID-token sign-in. Throws [SocialAuthCancelled] if dismissed.
  Future<void> signInWithGoogle();

  /// Native Facebook ID-token sign-in. Throws [SocialAuthCancelled] if dismissed.
  Future<void> signInWithFacebook();

  Future<void> signOut();
  Future<UserModel?> loadUser();
  UserModel? cachedUser();
  bool hasSession();
}

/// User closed the Google / Facebook sheet. Not an error.
class SocialAuthCancelled implements Exception {
  const SocialAuthCancelled();
}
