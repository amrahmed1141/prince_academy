import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';

class AuthRemoteDs {
  final SupabaseClient supabase;

  AuthRemoteDs(this.supabase);

  bool get hasSession => supabase.auth.currentSession != null;

  Future<String> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': 'user',
      },
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Could not create account. Try again.');
    }
    return user.id;
  }

  Future<void> updateUser({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'phone': phone,
        'role': 'user',
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email,
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
