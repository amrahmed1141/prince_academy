
import 'package:flutter/material.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/common_widgets/divider.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/common_widgets/social_button.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/login/widgets/Login_header.dart';
import 'package:prince_academy/features/auth/presentation/pages/auth/login/widgets/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.only(top: 56, left: 24, right: 24),
        child: Column(children: [
          // header
          LoginHeader(),
          LoginForm(),
         CustomDivider(indent:60 ),
          SocialButton(),
        ]),
      )),
    );
  }
}
