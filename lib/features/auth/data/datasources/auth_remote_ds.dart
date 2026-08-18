import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prince_academy/core/cache/local_cache_store.dart';
import 'package:prince_academy/core/config/oauth_config.dart';
import 'package:prince_academy/core/helpers/image_resize_helper.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDs {
  AuthRemoteDs(this.supabase, {LocalCacheStore? cache})
      : _cache = cache ?? LocalCacheStore.instance;

  final SupabaseClient supabase;
  final LocalCacheStore _cache;

  static const _avatarBucket = 'profile-avatars';

  bool get hasSession => supabase.auth.currentSession != null;

  /// Creates the auth user only — profile is saved separately via [saveProfile].
  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Failed to create account');
    }

    return user.id;
  }

  Future<void> saveProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedPhone = phone.trim();

    final row = {
      'id': userId,
      'full_name': trimmedName,
      'phone': trimmedPhone,
      'role': 'user',
    };

    try {
      await supabase.from('profiles').upsert(row, onConflict: 'id');
    } on PostgrestException {
      await supabase.from('profiles').update({
        'full_name': trimmedName,
        'phone': trimmedPhone,
        'role': 'user',
      }).eq('id', userId);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user');
    }

    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl;
    }

    await supabase.from('profiles').update(payload).eq('id', user.id);
  }

  Future<String> uploadAvatar(File file) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user');
    }

    final resized = await ImageResizeHelper.resizeCoachPhoto(file);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/avatar_$timestamp.jpg';

    await supabase.storage.from(_avatarBucket).upload(
          path,
          resized,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return supabase.storage.from(_avatarBucket).getPublicUrl(path);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    if (!OAuthConfig.isGoogleConfigured) {
      throw const AuthException(
        'Google sign-in is not set up yet. Add the Google Web Client ID.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: OAuthConfig.googleWebClientId,
      clientId: Platform.isIOS && OAuthConfig.googleIosClientId.isNotEmpty
          ? OAuthConfig.googleIosClientId
          : null,
    );

    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw const SocialAuthCancelled();
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      await googleSignIn.signOut();

      if (idToken == null) {
        throw const AuthException(
          'Google sign-in failed. Missing ID token.',
        );
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      await _ensureOAuthProfile();
    } on SocialAuthCancelled {
      rethrow;
    } on AuthException {
      rethrow;
    } on PlatformException catch (e) {
      if (_isGoogleCancel(e)) {
        throw const SocialAuthCancelled();
      }
      throw AuthException(e.message ?? 'Google sign-in failed.');
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      final LoginResult result;
      if (Platform.isIOS) {
        result = await FacebookAuth.instance.login(
          permissions: const ['public_profile', 'email'],
        );
      } else {
        result = await FacebookAuth.instance.login(
          permissions: const ['public_profile', 'email'],
          loginBehavior: LoginBehavior.webOnly,
        );
      }

      if (result.status == LoginStatus.cancelled) {
        throw const SocialAuthCancelled();
      }
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw AuthException(
          result.message?.trim().isNotEmpty == true
              ? result.message!
              : 'Facebook sign-in failed.',
        );
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: result.accessToken!.token,
      );
      await _ensureOAuthProfile();
    } on SocialAuthCancelled {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException(
        'Facebook sign-in failed. Check the Facebook app configuration.',
      );
    }
  }

  /// Inserts a member profile when the signup trigger did not create one.
  /// Does not overwrite an existing row (so an admin identity is left alone).
  Future<void> _ensureOAuthProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Social sign-in failed.');
    }

    Map<String, dynamic>? row;
    try {
      row = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
    } on PostgrestException {
      row = null;
    }
    if (row != null) return;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final rawName = (meta['full_name'] ?? meta['name'] ?? 'Member').toString();
    final name = rawName.trim().isEmpty ? 'Member' : rawName.trim();
    await saveProfile(
      userId: user.id,
      fullName: name,
      phone: (meta['phone'] ?? '').toString(),
    );
  }

  bool _isGoogleCancel(PlatformException e) {
    final code = e.code.toLowerCase();
    return code.contains('cancel');
  }

  Future<void> signOut() async {
    final userId = supabase.auth.currentUser?.id;
    await supabase.auth.signOut();
    if (userId != null) {
      await _cache.clearUser(userId);
    }
  }

  Future<UserModel?> fetchUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    Map<String, dynamic>? row;
    try {
      row = await supabase
          .from('profiles')
          .select('id, role, full_name, phone, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
    } on PostgrestException {
      // avatar_url may not exist until supabase/profile_avatars.sql is applied.
      row = await supabase
          .from('profiles')
          .select('id, role, full_name, phone')
          .eq('id', user.id)
          .maybeSingle();
    }

    if (row == null) {
      return _readCachedProfile(user.id, email: user.email);
    }

    final profile = UserModel.fromMap(
      Map<String, dynamic>.from(row),
      email: user.email,
    );
    await _cache.putJson(
      LocalCacheStore.userProfileKey(user.id),
      profile.toMap(),
    );
    return profile;
  }

  /// Instant profile from disk for cold start (before network returns).
  UserModel? cachedProfile() {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return _readCachedProfile(user.id, email: user.email);
  }

  UserModel? _readCachedProfile(String userId, {String? email}) {
    final map = _cache.getMap(LocalCacheStore.userProfileKey(userId));
    if (map == null) return null;
    try {
      return UserModel.fromMap(map, email: email);
    } catch (_) {
      return null;
    }
  }
}
