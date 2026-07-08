import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepo repo;
  StreamSubscription<dynamic>? _authSubscription;

  AuthBloc(this.repo) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<SignUpRequested>(_onSignUpRequested);
    on<AuthUserSignIn>(_onUserSignIn);
    on<AuthAdminSignIn>(_onAdminSignIn);
    on<AuthSignOut>(_onSignOut);

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        if (state is! AuthNoSession && state is! AuthInitial) {
          add(const AuthSignOut());
        }
      }
    });
  }

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      if (!repo.hasSession()) {
        emit(const AuthNoSession());
        return;
      }

      final userDoc = await repo.loadUser();
      if (userDoc == null) {
        await repo.signOut();
        emit(const AuthNoSession());
        return;
      }

      emit(AuthAuthed(userDoc));
    } on AuthException catch (e) {
      emit(AuthError(_friendlyAuthMessage(e.message)));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError(
          "Database missing: Please create the 'profiles' table in Supabase.",
        ));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Step 1: Create auth user — pass metadata for handle_new_user trigger.
      final response = await _supabase.auth.signUp(
        email: event.email.trim(),
        password: event.password,
        data: {
          'full_name': event.fullName.trim(),
          'phone': event.phone.trim(),
          'role': 'user',
        },
      );

      final user = response.user;
      if (user == null) {
        emit(const AuthError('Failed to create account'));
        return;
      }

      // Step 2: Insert profile row before emitting success.
      String? profileSaveWarning;
      try {
        await _saveProfileRow(
          userId: user.id,
          fullName: event.fullName,
          phone: event.phone,
        );
      } catch (_) {
        profileSaveWarning =
            'Account created but profile save failed. Please update your profile.';
      }

      // Step 3: Load profile and emit success (no signIn call needed).
      final userDoc = await repo.loadUser();
      if (userDoc == null) {
        if (profileSaveWarning != null) {
          emit(AuthError(profileSaveWarning));
        } else {
          emit(const AuthError('Profile not created yet. Try login.'));
        }
        return;
      }

      emit(AuthAuthed(userDoc, profileSaveWarning: profileSaveWarning));
    } on AuthException catch (e) {
      emit(AuthError(_friendlyAuthMessage(e.message)));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError(
          "Database missing: Please create the 'profiles' table in Supabase.",
        ));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError('Signup failed: ${e.toString()}'));
    }
  }

  Future<void> _saveProfileRow({
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
      await _supabase.from('profiles').upsert(row, onConflict: 'id');
    } on PostgrestException {
      await _supabase.from('profiles').update({
        'full_name': trimmedName,
        'phone': trimmedPhone,
        'role': 'user',
      }).eq('id', userId);
    }
  }

  Future<void> _onUserSignIn(
    AuthUserSignIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await repo.signIn(event.email, event.password);

      final userDoc = await repo.loadUser();
      if (userDoc == null) {
        emit(const AuthError('Profile missing. Contact support.'));
        return;
      }

      emit(AuthAuthed(userDoc));
    } on AuthException catch (e) {
      emit(AuthError(_friendlyAuthMessage(e.message)));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError(
          "Database missing: Please create the 'profiles' table in Supabase.",
        ));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAdminSignIn(
    AuthAdminSignIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await repo.signIn(event.email, event.password);

      final userDoc = await repo.loadUser();
      if (userDoc == null) {
        emit(const AuthError('Profile missing. Contact support.'));
        return;
      }

      if (userDoc.role != 'admin') {
        await repo.signOut();
        emit(const AuthError('Not an admin account.'));
        return;
      }

      emit(AuthAuthed(userDoc));
    } on AuthException catch (e) {
      emit(AuthError(_friendlyAuthMessage(e.message)));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError(
          "Database missing: Please create the 'users' table in Supabase.",
        ));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await repo.signOut();
      emit(const AuthNoSession());
    } on AuthException catch (e) {
      emit(AuthError(_friendlyAuthMessage(e.message)));
    } on PostgrestException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}

String _friendlyAuthMessage(String message) {
  try {
    final decoded = jsonDecode(message);
    if (decoded is Map) {
      final text = decoded['message'] as String?;
      if (text != null && text.isNotEmpty) {
        if (text.contains('Database error saving new user')) {
          return 'Could not create your profile. Ask an admin to run '
              'supabase/fix_signup_trigger.sql in Supabase, then try again.';
        }
        return text;
      }
    }
  } catch (_) {}

  if (message.contains('Database error saving new user')) {
    return 'Could not create your profile. Ask an admin to run '
        'supabase/fix_signup_trigger.sql in Supabase, then try again.';
  }
  return message;
}
