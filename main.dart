import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart'; // Mengimpor splash screen sebagai gerbang utama

void main() async {
  // Memastikan binding framework Flutter sudah siap sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase menggunakan konfigurasi platform yang sesuai
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Jalankan aplikasi utama
  runApp(const EcoConnectApp());
}

class EcoConnectApp extends StatelessWidget {
  const EcoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoConnect',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      theme: ThemeData(
        // Menggunakan warna hijau utama yang konsisten dengan tema lingkungan
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      // Halaman pertama yang akan muncul adalah SplashScreen
      // Setelah 3 detik, SplashScreen akan otomatis mengarahkan ke OnboardingPage
      home: const SplashScreen(),
    );
  }
}