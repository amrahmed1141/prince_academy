import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/app/app.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/auth_background.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/auth_card.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/auth_text_field.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/gradient_button.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthError) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (state is AuthAuthed) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Login Successful! Welcome, ${state.user.fullName ?? "Admin"}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthenticatedShell(
            isAdmin: state.user.role == 'admin',
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthState,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: EColorConstants.authBackgroundGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AuthBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth > 600 ? 48.0 : 20.0;
                    final logoSize =
                        constraints.maxWidth > 600 ? 160.0 : 120.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.03),
                            Image.asset(
                              'assets/icons/logo.png',
                              height: logoSize,
                              width: logoSize,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Admin Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Restricted access for administrators',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 30),
                            AuthCard(
                              child: _buildForm(context),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              label: Text(
                                'Back to Member Login',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final loading =
        context.select<AuthBloc, bool>((b) => b.state is AuthLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _email,
          label: 'Admin Email',
          hintText: 'admin@example.com',
          prefixIcon: Icons.admin_panel_settings_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _password,
          label: 'Password',
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscure,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: EColorConstants.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          text: 'Login as Admin',
          loading: loading,
          onPressed: () {
            context.read<AuthBloc>().add(
                  AuthAdminSignIn(_email.text.trim(), _password.text.trim()),
                );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Admin login only (no signup)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EColorConstants.authPlaceholderGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
