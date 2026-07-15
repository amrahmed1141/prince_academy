import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/cache/local_cache_store.dart';
import 'package:prince_academy/core/helpers/image_resize_helper.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';

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
