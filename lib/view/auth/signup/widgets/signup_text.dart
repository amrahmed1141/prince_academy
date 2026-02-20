import 'package:flutter/material.dart';
import 'package:prince_academy/utils/constants/colors.dart';
import 'package:prince_academy/view/auth/login/login.dart';
import 'package:prince_academy/view/bottom_navigation/navigation_bottom.dart';

class SignupText extends StatelessWidget {
  const SignupText({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already Have an Account',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        TextButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginScreen()));
            },
            child: const Text(
              'Login',
              style: TextStyle(
                  color: EColorConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ))
      ],
    );
  }
}
