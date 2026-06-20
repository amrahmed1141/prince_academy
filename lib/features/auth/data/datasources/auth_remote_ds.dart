import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';

class AuthRemoteDs {
  final SupabaseClient supabase;

  AuthRemoteDs(this.supabase);

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

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => supabase.auth.signOut();

  Future<UserModel?> fetchUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;

    return UserModel.fromMap(Map<String, dynamic>.from(row));
  }
}
