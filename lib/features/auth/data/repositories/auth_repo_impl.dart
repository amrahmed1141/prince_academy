import 'package:prince_academy/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final AuthRemoteDs ds;
  AuthRepoImpl(this.ds);

  @override
  bool hasSession() => ds.hasSession;

  @override
  Future<void> signUp(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    await ds.signUp(
      email: email, 
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await ds.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() => ds.signOut();

  @override
  Future<UserModel?> loadUser() => ds.fetchUser();
}