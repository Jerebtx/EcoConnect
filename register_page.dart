import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controller untuk menangkap input teks
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Daftar minat lingkungan
  final List<String> _ecoInterests = [
    'Bebas Plastik',
    'Diet Vegan',
    'Hemat Energi',
    'Transportasi Umum',
    'Daur Ulang'
  ];

  final List<String> _selectedInterests = [];

  Future<void> _registerUser() async {
    // 1. Validasi Input Dasar
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError("Semua kolom harus diisi!");
      return;
    }

    if (_selectedInterests.isEmpty) {
      _showError("Pilih minimal 1 minat lingkungan.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Validasi Username Unik (Cek apakah username sudah dipakai orang lain)
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: _usernameController.text.trim().toLowerCase())
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        _showError("Username sudah digunakan, cari yang lain ya!");
        setState(() => _isLoading = false);
        return;
      }

      // 3. Daftarkan Akun di Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 4. Simpan Data Profil Lengkap ke Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'email': _emailController.text.trim(),
        'interests': _selectedInterests,
        'points': 0,
        'streak': 0, // Field baru
        'lastActionDate': null, // Field baru
        'weeklyActions': 0, // Field baru
        'weeklyCo2': 0.0, // Field baru
        'lastWeeklyReset': FieldValue.serverTimestamp(), // Field baru
        'followers': [],
        'following': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Pindah ke HomePage
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String pesan = "Terjadi kesalahan.";
      if (e.code == 'email-already-in-use') pesan = "Email sudah terdaftar.";
      if (e.code == 'weak-password') pesan = "Password terlalu lemah (min. 6 karakter).";
      _showError(pesan);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Color(0xFF2E7D32))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Buat Akun EcoConnect", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              const SizedBox(height: 8),
              const Text("Isi data dirimu untuk mulai beraksi.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Input Nama
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Input Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username (unik)',
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: "Contoh: jeremiah_eco",
                ),
              ),
              const SizedBox(height: 16),

              // Input Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Input Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              const Text("Minat Lingkungan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8.0,
                children: _ecoInterests.map((interest) {
                  bool isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        selected ? _selectedInterests.add(interest) : _selectedInterests.remove(interest);
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                  : ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Daftar Sekarang", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}