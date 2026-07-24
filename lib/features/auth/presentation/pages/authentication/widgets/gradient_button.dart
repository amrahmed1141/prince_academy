import 'package:flutter/material.dart';
import 'package:load_it/load_it.dart';
import 'package:prince_academy/core/constants/colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? EColorConstants.authPrimaryGradient : null,
          color: enabled ? null : EColorConstants.authFieldBorder,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: EColorConstants.primaryColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: loading
                  ? const BouncingDotsIndicator(
                      color: Colors.white,
                      size: 28,
                    )
                  : Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
