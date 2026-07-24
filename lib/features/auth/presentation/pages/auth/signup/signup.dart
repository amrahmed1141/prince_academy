import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/app/app.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/common_widgets/divider.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/common_widgets/social_button.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/signup/widgets/signup_form.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/signup/widgets/signup_header.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/signup/widgets/signup_text.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (state is AuthAuthed) {
          if (state.profileSaveWarning != null) {
            rootScaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(state.profileSaveWarning!),
                backgroundColor: Colors.orange,
              ),
            );
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AuthenticatedShell(
                isAdmin: state.user.role == 'admin',
              ),
            ),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SignupHeader(),
                const SizedBox(height: 10),
                const SignupForm(),
                const SignupText(),
                const SizedBox(height: 10),
                const CustomDivider(indent: 60),
                const SocialButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
