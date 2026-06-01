import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/text.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({super.key});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
        child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                    labelText: ETexts.firstNameLabel,
                    prefixIcon: Icon(CupertinoIcons.person)),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                    labelText: ETexts.lastNameLabel,
                    prefixIcon: Icon(CupertinoIcons.person)),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 15,
        ),

        /// username
        TextFormField(
          decoration: const InputDecoration(
              labelText: ETexts.usernameLabel,
              prefixIcon: Icon(CupertinoIcons.person_alt_circle)),
        ),
        const SizedBox(
          height: 15,
        ),

        /// email
        TextFormField(
          decoration: const InputDecoration(
              labelText: ETexts.emailLabel,
              prefixIcon: Icon(CupertinoIcons.mail)),
        ),
        const SizedBox(
          height: 15,
        ),

        /// phone number
        TextFormField(
          decoration: const InputDecoration(
              labelText: ETexts.phoneNumberLabel,
              prefixIcon: Icon(CupertinoIcons.phone)),
        ),
        const SizedBox(
          height: 15,
        ),

        // password
        TextFormField(
          decoration: const InputDecoration(
              labelText: ETexts.passwordLabel,
              prefixIcon: Icon(Icons.password_outlined),
              suffixIcon: Icon(CupertinoIcons.eye_slash_fill)),
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    ));
  }
}
