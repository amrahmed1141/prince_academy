import 'dart:io';

import 'package:prince_academy/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl(this.ds);

  final AuthRemoteDs ds;

  @override
  bool hasSession() => ds.hasSession;

  @override
  Future<String> signUp(String email, String password) {
    return ds.signUp(email: email, password: password);
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) {
    return ds.saveProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) {
    return ds.updateProfile(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<String> uploadAvatar(File file) => ds.uploadAvatar(file);

  @override
  Future<void> signIn(String email, String password) async {
    await ds.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() => ds.signOut();

  @override
  Future<UserModel?> loadUser() => ds.fetchUser();

  @override
  UserModel? cachedUser() => ds.cachedProfile();
}
