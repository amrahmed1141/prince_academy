import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/auth_page.dart';
import 'package:prince_academy/app/bottom_navigation/navigation_bottom.dart';
import 'package:prince_academy/app/splash/splash_screen.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_home.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../core/di/injection.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class PrinceAcademyApp extends StatelessWidget {
  const PrinceAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthStarted()),
        ),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Prince Academy',
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial) {
              return const SplashScreen();
            } else if (state is AuthAuthed) {
              if (state.user.role == 'admin') {
                return const AdminHomeScreen();
              }
              return const NavigationBottom();
            } else {
              // Includes AuthNoSession and AuthError
              return const AuthPage();
            }
          },
        ),
      ),
    );
  }
}