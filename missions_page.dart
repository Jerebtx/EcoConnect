import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Variabel global agar bisa dibaca oleh halaman Home
final List<Map<String, dynamic>> globalMissions = [
  {'id': 'm1', 'title': 'Bring Tumbler', 'desc': 'Use your own tumbler', 'co2': 0.5, 'icon': Icons.coffee_rounded, 'color': Colors.amber},
  {'id': 'm2', 'title': 'Recycle Plastic', 'desc': 'Separate plastic waste', 'co2': 1.2, 'icon': Icons.recycling_rounded, 'color': Colors.green},
  {'id': 'm3', 'title': 'Save Electricity', 'desc': 'Turn off unused lights', 'co2': 2.0, 'icon': Icons.bolt_rounded, 'color': Colors.orange},
  {'id': 'm4', 'title': 'Public Transport', 'desc': 'Take bus or train', 'co2': 3.5, 'icon': Icons.directions_bus_rounded, 'color': Colors.lightBlue},
  {'id': 'm5', 'title': 'Plant-based Meal', 'desc': 'Eat without meat', 'co2': 1.0, 'icon': Icons.eco_outlined, 'color': Colors.lightGreen},
];

class MissionsPage extends StatelessWidget {
  const MissionsPage({super.key});

  // --- LOGIKA MENYELESAIKAN MISI (SINKRON DENGAN HOME) ---
  void _completeMission(BuildContext context, Map<String, dynamic> mission, String uid, Map<String, dynamic> user) async {
    try {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      Timestamp? lastTs = user['lastActionDate'] as Timestamp?;
      DateTime? lastDay = lastTs != null ? DateTime(lastTs.toDate().year, lastTs.toDate().month, lastTs.toDate().day) : null;

      int currentStreak = user['streak'] ?? 0;
      int newStreak = currentStreak;

      // Hitung streak baru
      if (lastDay == null) {
        newStreak = 1;
      } else if (today.difference(lastDay).inDays == 1) {
        newStreak += 1;
      } else if (today.difference(lastDay).inDays >= 2) {
        newStreak = 1;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'points': FieldValue.increment(10),
        'completedMissions': FieldValue.arrayUnion([mission['id']]),
        'weeklyActions': FieldValue.increment(1),
        'weeklyCo2': FieldValue.increment(mission['co2']),
        'lastActionDate': FieldValue.serverTimestamp(),
        'streak': newStreak,
      });

      if (context.mounted) {
        _showSuccessPopup(context, mission['title'], newStreak, mission['co2']);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- POP-UP KEREN SAAT MISI SELESAI ---
  void _showSuccessPopup(BuildContext context, String title, int streak, double co2) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ikon Perayaan
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF66BB6A), size: 60),
                  ),
                  const SizedBox(height: 20),

                  // Teks Ucapan
                  const Text("Kerja Bagus!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 8),
                  Text(
                    "Kamu telah menyelesaikan misi\n'$title'",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Info Poin, Streak, dan CO2
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPopupStat(Icons.bolt, Colors.orange, "+10", "Poin"),
                        _buildPopupStat(Icons.local_fire_department, Colors.redAccent, "$streak", "Streak"),
                        _buildPopupStat(Icons.water_drop_outlined, Colors.blue, "${co2}kg", "CO₂ Saved"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Tutup
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text("Lanjutkan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildPopupStat(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              List completedMissions = userData['completedMissions'] ?? [];
              double progress = globalMissions.isEmpty ? 0 : completedMissions.length / globalMissions.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Daily Missions", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    const Text("Selesaikan misi hijau setiap hari", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 24),

                    // --- PROGRESS CARD ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF66BB6A), borderRadius: BorderRadius.circular(25)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Today's Progress", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
                                child: Text("${completedMissions.length}/${globalMissions.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- DAFTAR MISI ---
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: globalMissions.length,
                      itemBuilder: (context, index) {
                        var mission = globalMissions[index];
                        bool isDone = completedMissions.contains(mission['id']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              // Ikon Misi
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: mission['color'].withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                                child: Icon(mission['icon'], color: mission['color'], size: 30),
                              ),
                              const SizedBox(width: 16),

                              // Detail Misi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mission['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(mission['desc'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text("Save ${mission['co2']}kg CO₂", style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),

                              // --- RADIO BUTTON INTERAKTIF ---
                              GestureDetector(
                                onTap: () {
                                  // Hanya bisa diklik jika misi belum selesai
                                  if (!isDone) {
                                    _completeMission(context, mission, uid, userData);
                                  }
                                },
                                // Memperbesar area klik (hitbox) agar lebih mudah dipencet
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isDone ? const Color(0xFF66BB6A) : Colors.grey.shade300,
                                      size: 32
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }
}