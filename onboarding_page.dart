import 'package:flutter/material.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data untuk 3 halaman onboarding (pakai Ikon sementara)
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Aksi Kecil, Dampak Besar",
      "description": "Mulai perjalanan ramah lingkunganmu hari ini. Setiap aksi kecil yang kamu lakukan sangat berarti bagi bumi.",
      "icon": Icons.eco_rounded, // Ikon sementara
    },
    {
      "title": "Selesaikan Misi Harian",
      "description": "Dapatkan Eco Points dengan menyelesaikan misi harian seperti membawa tumbler atau menggunakan transportasi umum.",
      "icon": Icons.track_changes_rounded, // Ikon sementara
    },
    {
      "title": "Bergabung Bersama Komunitas",
      "description": "Bagikan perjalananmu, temukan teman baru, dan berkompetisi di Leaderboard untuk menjadi Eco Warrior terbaik!",
      "icon": Icons.people_alt_rounded, // Ikon sementara
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Tombol "Lewati" di pojok kanan atas
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                },
                child: const Text("Lewati", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),

            // Bagian PageView (Isi konten yang bisa di-swipe)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ikon besar sebagai pengganti gambar sementara
                        Icon(
                          _onboardingData[index]["icon"],
                          size: 150,
                          color: const Color(0xFF66BB6A),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _onboardingData[index]["title"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingData[index]["description"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indikator Titik-titik & Tombol Lanjut
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Membuat titik-titik indikator (Dots)
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                          (index) => buildDot(index, context),
                    ),
                  ),

                  // Tombol "Lanjut" atau "Mulai"
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        // Jika di halaman terakhir, pindah ke Login
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      } else {
                        // Jika belum, geser ke halaman berikutnya
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1 ? "Mulai" : "Lanjut",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menggambar desain titik indikator
  Widget buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentPage == index ? 25 : 10, // Kalau aktif, titiknya memanjang
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index ? const Color(0xFF2E7D32) : Colors.grey.shade300,
      ),
    );
  }
}