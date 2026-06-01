import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/text.dart';

class SignupHeader extends StatelessWidget {
  const SignupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
           const SizedBox(
              height: 20,
            ),
            Image.asset(
              'assets/icons/logo.png',
              height: 100,
              width: 150,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              ETexts.signupSubTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
    ],);
  }
}