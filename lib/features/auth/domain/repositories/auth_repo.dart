import 'package:prince_academy/features/auth/data/models/app_user.dart';

abstract class AuthRepo {
  Future<void> signUp(
    String email,
    String password,
    String fullName,
    String phone,
  );
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> loadUser();
  bool hasSession();
}
