import 'package:flutter/material.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController _inputController = TextEditingController();
  String _hasilPerhitungan = "";

  void _hitungJejakKarbon() {
    String inputMentah = _inputController.text;

    // Postel's Law (Fleksibilitas Input):
    // Pengguna mungkin mengetik "10.000", "10,000", atau "10 000".
    // Sistem membersihkan karakter selain angka agar tidak terjadi error (crash).
    String inputBersih = inputMentah.replaceAll(RegExp(r'[^0-9]'), '');

    if (inputBersih.isEmpty) {
      setState(() {
        _hasilPerhitungan = "Masukkan angka jarak tempuh dulu ya 😉";
      });
      return;
    }

    double jarak = double.parse(inputBersih);

    // Tesler's Law (Manajemen Kompleksitas):
    // Perhitungan di balik layar melibatkan rumus emisi kendaraan dan konversi ke jumlah pohon,
    // tapi pengguna hanya perlu tahu: "Saya naik sepeda X km, ini dampaknya."
    double hematKarbon = jarak * 0.192; // Asumsi hemat 0.192 kg CO2 per km
    int pohonEkuivalen = (hematKarbon / 21).ceil(); // Asumsi 1 pohon menyerap 21kg CO2/tahun

    setState(() {
      _hasilPerhitungan = "Kamu telah menghemat ${hematKarbon.toStringAsFixed(2)} kg Karbon!\n"
          "Itu setara dengan kerja $pohonEkuivalen pohon dalam setahun 🌳";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Kalkulator Dampak"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Hitung Dampak Aksimu",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Berapa jarak yang kamu tempuh dengan sepeda atau jalan kaki hari ini? (dalam km)"),
            const SizedBox(height: 24),

            TextField(
              controller: _inputController,
              keyboardType: TextInputType.text, // Sengaja text agar kita bisa mendemokan Postel's law
              decoration: InputDecoration(
                labelText: 'Contoh: 10.5 atau 10,500',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.directions_bike),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _hitungJejakKarbon,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Hitung Dampak", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                _hasilPerhitungan.isEmpty ? "Hasil perhitungan akan muncul di sini." : _hasilPerhitungan,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
              ),
            )
          ],
        ),
      ),
    );
  }
}