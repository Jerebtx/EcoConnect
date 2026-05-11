import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'onboarding_page.dart';
import 'home_page.dart'; // Import HomePage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Mengatur waktu tunggu selama 3 detik sebelum cek status login
    Timer(const Duration(seconds: 3), () {
      // Mengecek apakah ada user yang sedang login
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Jika sudah login, langsung lompat ke HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Jika belum login, masuk ke Onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan logo kamu
            Image.asset(
              'assets/eco.png',
              height: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ],
        ),
      ),
    );
  }
}