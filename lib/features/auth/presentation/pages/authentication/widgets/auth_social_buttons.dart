import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/constants/image_string.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final loading =
        context.select<AuthBloc, bool>((bloc) => bloc.state is AuthLoading);

    return Column(
      children: [
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(
              child: Divider(
                color: EColorConstants.authFieldBorder,
                thickness: 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: EColorConstants.authPlaceholderGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: EColorConstants.authFieldBorder,
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                asset: EImages.googleLogo,
                enabled: !loading,
                onPressed: () => context.read<AuthBloc>().add(
                      const AuthGoogleSignIn(),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'Facebook',
                asset: EImages.facebookLogo,
                enabled: !loading,
                onPressed: () => context.read<AuthBloc>().add(
                      const AuthFacebookSignIn(),
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.asset,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String asset;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: EColorConstants.authTextDarkBrown,
          side: const BorderSide(color: EColorConstants.authFieldBorder),
          backgroundColor: EColorConstants.authFieldBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, width: 22, height: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
