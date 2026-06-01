import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepo repo;
  StreamSubscription<dynamic>? _authSubscription;

  AuthBloc(this.repo) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthUserSignUp>(_onUserSignUp);
    on<AuthUserSignIn>(_onUserSignIn);
    on<AuthAdminSignIn>(_onAdminSignIn);
    on<AuthSignOut>(_onSignOut);

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        if (state is! AuthNoSession && state is! AuthInitial) {
          add(AuthSignOut());
        }
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    // Guaranteed minimum visibility for Splash Screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      if (!repo.hasSession()) {
        emit(AuthNoSession());
        return;
      }

      final userDoc = await repo.loadUser();
      if (userDoc == null) {
        await repo.signOut();
        emit(AuthNoSession());
        return;
      }

      emit(AuthAuthed(userDoc));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError("Database missing: Please create the 'profiles' table in Supabase."));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUserSignUp(AuthUserSignUp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await repo.signUp(event.email, event.password, event.fullName, event.phone);

      final userDoc = await repo.loadUser();
      if (userDoc == null) {
        emit(const AuthError('Profile not created yet. Try login.'));
        return;
      }

      emit(AuthAuthed(userDoc));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError("Database missing: Please create the 'profiles' table in Supabase."));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUserSignIn(AuthUserSignIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await repo.signIn(event.email, event.password);

      final userDoc = await repo.loadUser();
      if (userDoc == null) {
        emit(const AuthError('Profile missing. Contact support.'));
        return;
      }

      emit(AuthAuthed(userDoc));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError("Database missing: Please create the 'profiles' table in Supabase."));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAdminSignIn(AuthAdminSignIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
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
      emit(AuthError(e.message));
    } on PostgrestException catch (e) {
       if (e.code == 'PGRST205' || e.code == '404') {
        emit(const AuthError("Database missing: Please create the 'users' table in Supabase."));
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await repo.signOut();
      emit(AuthNoSession());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } on PostgrestException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}