import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/text.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/common_widgets/divider.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/common_widgets/social_button.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/signup/widgets/signup_form.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/signup/widgets/signup_header.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/signup/widgets/signup_text.dart';
import 'package:prince_academy/app/bottom_navigation/navigation_bottom.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SignupHeader(),
            const SizedBox(
              height: 10,
            ),
            const SignupForm(),
            const SignupText(),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                     Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NavigationBottom()));
                  }, child: const Text(ETexts.signupButton)),
            ),
            const CustomDivider(indent: 60),
            const SocialButton()
          ]),
        ),
      ),
    );
  }
}
