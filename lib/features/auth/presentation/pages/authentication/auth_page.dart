import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/app/app.dart';
import 'package:prince_academy/app/bottom_navigation/navigation_bottom.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/constants/text.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_home.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/auth_background.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/auth_card.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/auth_tab_bar.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/auth_text_field.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/widgets/gradient_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index != _currentIndex) {
      setState(() {
        _prevIndex = _currentIndex;
        _currentIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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
            'Login Successful! Welcome back, ${state.user.fullName ?? "User"}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => state.user.role == 'admin'
              ? const AdminHomeScreen()
              : const NavigationBottom(),
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
                    final logoSize = constraints.maxWidth > 600 ? 200.0 : 165.0;

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
                            SizedBox(height: constraints.maxHeight * 0.015),
                            Image.asset(
                              'assets/icons/logo.png',
                              height: logoSize,
                              width: logoSize,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Prince MMA Academy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'TRAIN HARD. FIGHT SMART.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 26),
                            AuthTabBar(controller: _tabController),
                            const SizedBox(height: 20),
                            AuthCard(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                    return Stack(
                                      alignment: Alignment.topCenter,
                                      children: <Widget>[
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) {
                                    final isCurrent = child.key ==
                                        ValueKey<int>(_currentIndex);
                                    final double slideDirection =
                                        _currentIndex >= _prevIndex
                                            ? 1.0
                                            : -1.0;

                                    final offsetTween = isCurrent
                                        ? Tween<Offset>(
                                            begin: Offset(
                                                slideDirection * 0.15, 0.0),
                                            end: Offset.zero,
                                          )
                                        : Tween<Offset>(
                                            begin: Offset(
                                                -slideDirection * 0.15, 0.0),
                                            end: Offset.zero,
                                          );

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position:
                                            offsetTween.animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: [
                                    const _SignInTab(key: ValueKey(0)),
                                    const _SignUpTab(key: ValueKey(1)),
                                    const _AdminTab(key: ValueKey(2)),
                                  ][_currentIndex],
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
}

class _SignInTab extends StatefulWidget {
  const _SignInTab({super.key});

  @override
  State<_SignInTab> createState() => _SignInTabState();
}

class _SignInTabState extends State<_SignInTab> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading =
        context.select<AuthBloc, bool>((b) => b.state is AuthLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _email,
          label: 'Email Address',
          hintText: 'you@example.com',
          prefixIcon: Icons.email_outlined,
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
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                activeColor: EColorConstants.primaryColor,
                checkColor: Colors.white,
                side: const BorderSide(color: EColorConstants.authFieldBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              ETexts.rememberMeLabel,
              style: TextStyle(
                color: EColorConstants.authTextDarkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: EColorConstants.primaryColor,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                ETexts.forgotPasswordTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GradientButton(
          text: 'Sign In',
          loading: loading,
          onPressed: () {
            context.read<AuthBloc>().add(
                  AuthUserSignIn(_email.text.trim(), _password.text.trim()),
                );
          },
        ),
      ],
    );
  }
}

class _SignUpTab extends StatefulWidget {
  const _SignUpTab({super.key});

  @override
  State<_SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<_SignUpTab> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading =
        context.select<AuthBloc, bool>((b) => b.state is AuthLoading);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _fullName,
          label: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _phone,
          label: 'Phone',
          hintText: 'Enter your phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _email,
          label: 'Email Address',
          hintText: 'you@example.com',
          prefixIcon: Icons.email_outlined,
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
          text: 'Sign Up',
          loading: loading,
          onPressed: () {
            context.read<AuthBloc>().add(
                  AuthUserSignUp(
                    _email.text.trim(),
                    _password.text.trim(),
                    _fullName.text.trim(),
                    _phone.text.trim(),
                  ),
                );
          },
        ),
      ],
    );
  }
}

class _AdminTab extends StatefulWidget {
  const _AdminTab({super.key});

  @override
  State<_AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<_AdminTab> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
