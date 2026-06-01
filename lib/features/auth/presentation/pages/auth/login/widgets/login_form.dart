import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/text.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/signup/signup.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
        child: Column(
      children: [
        //email
        TextFormField(
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              labelText: ETexts.emailLabel),
        ),
        const SizedBox(
          height: 20,
        ),

        //password
        TextFormField(
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock),
              suffixIcon: Icon(CupertinoIcons.eye_slash),
              labelText: ETexts.passwordLabel),
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // remember me
            Row(
              children: [
                Checkbox(value: true, onChanged: (value) {}),
                Text(ETexts.rememberMeLabel),
              ],
            ),

            ///  forget password
            TextButton(
                onPressed: () {}, child: const Text(ETexts.forgotPasswordTitle))
          ],
        ),
        const SizedBox(
          height: 15,
        ),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {}, child: const Text(ETexts.loginButton))),
        const SizedBox(
          height: 15,
        ),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignupScreen()));
              },
              child: const Text(ETexts.createAccountButton)),
        )
      ],
    ));
  }
}
