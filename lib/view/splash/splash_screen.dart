import 'package:flutter/material.dart';
import 'package:prince_academy/view/auth/login/login.dart';
import 'package:prince_academy/view/home/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Center(child: Image.asset('assets/icons/logo.png',height: 400,fit:BoxFit.cover,)),
          ],
        ),
     
    );
  }
}
