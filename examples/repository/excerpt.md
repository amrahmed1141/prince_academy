# Repository excerpt (auth boundary)

SOURCE:
- `lib/features/auth/domain/repositories/auth_repo.dart`
- `lib/features/auth/data/repositories/auth_repo_impl.dart`
- `lib/core/di/injection.dart`

```dart
// domain
abstract class AuthRepo {
  Future<String> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> loadUser();
  UserModel? cachedUser();
  bool hasSession();
  // … profile / avatar methods — see source
}
```

```dart
// data
class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl(this.ds);

  final AuthRemoteDs ds;

  @override
  bool hasSession() => ds.hasSession;

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

  // remaining methods delegate to AuthRemoteDs — see source
}
```

```dart
// DI
sl.registerLazySingleton<AuthRemoteDs>(
  () => AuthRemoteDs(sl(), cache: sl()),
);
sl.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(sl()));
sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
```
