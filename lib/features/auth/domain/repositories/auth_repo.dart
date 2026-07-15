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
  Future<void> signOut();
  Future<UserModel?> loadUser();
  UserModel? cachedUser();
  bool hasSession();
}
