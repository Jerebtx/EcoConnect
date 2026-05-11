import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forum_page.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'missions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeContent(onNavigate: _changeTab),
      const MissionsPage(),
      const SearchPage(),
      const ForumPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF66BB6A),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: "Missions"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Cari"),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: "Forum"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeContent({super.key, required this.onNavigate});

  // --- LOGIKA SYNC & RESET OTOMATIS ---
  void _syncUserStats(String uid, Map<String, dynamic> user) async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    Timestamp? lastTs = user['lastActionDate'] as Timestamp?;
    DateTime? lastDate = lastTs?.toDate();
    DateTime? lastDay = lastDate != null ? DateTime(lastDate.year, lastDate.month, lastDate.day) : null;

    Map<String, dynamic> updates = {};

    if (lastDay != null && today.isAfter(lastDay)) {
      updates['completedMissions'] = [];
    }

    if (lastDay != null) {
      int difference = today.difference(lastDay).inDays;
      if (difference >= 2) {
        updates['streak'] = 0;
      }
    }

    if (now.weekday == DateTime.monday) {
      Timestamp? lastWeeklyTs = user['lastWeeklyReset'] as Timestamp?;
      if (lastWeeklyTs != null) {
        DateTime lastWeekly = lastWeeklyTs.toDate();
        if (today.difference(DateTime(lastWeekly.year, lastWeekly.month, lastWeekly.day)).inDays >= 1) {
          updates['weeklyActions'] = 0;
          updates['weeklyCo2'] = 0.0;
          updates['lastWeeklyReset'] = FieldValue.serverTimestamp();
        }
      }
    }

    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(updates);
    }
  }

  // --- LOGIKA SELESAI MISI & POP-UP ---
  void _completeMissionFromHome(BuildContext context, Map<String, dynamic> mission, String uid, Map<String, dynamic> user) async {
    try {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      Timestamp? lastTs = user['lastActionDate'] as Timestamp?;
      DateTime? lastDay = lastTs != null ? DateTime(lastTs.toDate().year, lastTs.toDate().month, lastTs.toDate().day) : null;

      int currentStreak = user['streak'] ?? 0;
      int newStreak = currentStreak;

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
        _showSuccessPopup(context, mission['title'], newStreak, mission['co2'].toDouble());
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showSuccessPopup(BuildContext context, String title, int streak, double co2) {
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF66BB6A), size: 60),
                  ),
                  const SizedBox(height: 20),
                  const Text("Luar Biasa!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 8),
                  Text("Misi '$title' selesai!", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPopupStat(Icons.bolt, Colors.orange, "+10", "Poin"),
                      _buildPopupStat(Icons.local_fire_department, Colors.redAccent, "$streak", "Streak"),
                      _buildPopupStat(Icons.water_drop_outlined, Colors.blue, "${co2}kg", "CO₂"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Lanjut", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var user = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        _syncUserStats(uid, user);

        List completedMissions = user['completedMissions'] ?? [];
        int streakCount = user['streak'] ?? 0;

        Map<String, dynamic>? nextMission;
        for (var mission in globalMissions) {
          if (!completedMissions.contains(mission['id'])) {
            nextMission = mission;
            break;
          }
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi, ${user['name']} 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                            const SizedBox(width: 4),
                            Text("$streakCount Day Streak", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const CircleAvatar(backgroundColor: Color(0xFFF5F5F5), child: Icon(Icons.notifications_none, color: Colors.black))
                  ],
                ),
                const SizedBox(height: 25),

                // Impact Card (Sinkron Mingguan)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: Text("Impact This Week", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildImpactStat("${user['weeklyActions'] ?? 0}", "Actions", Icons.eco_outlined),
                          _buildImpactStat("${(user['weeklyCo2'] ?? 0.0).toStringAsFixed(1)}kg", "CO₂ Saved", Icons.water_drop_outlined),
                          _buildImpactStat("${user['points'] ?? 0}", "Total Poin", Icons.bolt),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: globalMissions.isEmpty ? 0 : completedMissions.length / globalMissions.length,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Today's Mission
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Mission", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Chip(label: Text("Daily", style: TextStyle(fontSize: 12)), backgroundColor: Color(0xFFE8F5E9), side: BorderSide.none),
                  ],
                ),
                const SizedBox(height: 12),

                nextMission != null
                    ? Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: nextMission['color'].withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                      child: Icon(nextMission['icon'], color: nextMission['color']),
                    ),
                    title: Text(nextMission['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Save ${nextMission['co2']}kg CO₂"),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.grey, size: 30),
                      onPressed: () => _completeMissionFromHome(context, nextMission!, uid, user),
                    ),
                  ),
                )
                    : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                  child: const Row(
                    children: [
                      Icon(Icons.celebration, color: Colors.green, size: 40),
                      SizedBox(width: 15),
                      Expanded(child: Text("Hebat! Kamu sudah menyelesaikan semua misi hari ini.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Trending Forum
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Trending on Forum", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => onNavigate(3),
                      child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').limit(10).snapshots(),
                  builder: (context, postSnapshot) {
                    if (!postSnapshot.hasData) return const SizedBox.shrink();

                    var posts = postSnapshot.data!.docs.toList();
                    posts.sort((a, b) {
                      var dataA = a.data() as Map<String, dynamic>;
                      var dataB = b.data() as Map<String, dynamic>;
                      int scoreA = (dataA['likes'] as List).length + (dataA['commentCount'] as int);
                      int scoreB = (dataB['likes'] as List).length + (dataB['commentCount'] as int);
                      return scoreB.compareTo(scoreA);
                    });

                    var trendingList = posts.take(2).toList();
                    if (trendingList.isEmpty) return const Text("Belum ada diskusi trending.", style: TextStyle(color: Colors.grey));

                    return Column(
                      children: trendingList.map((post) {
                        var data = post.data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF66BB6A),
                                child: Text(data['authorName'].substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['content'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    Text("oleh ${data['authorName']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text("${(data['likes'] as List).length}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.chat_bubble, color: Colors.grey, size: 14),
                                  const SizedBox(width: 4),
                                  Text("${data['commentCount']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 25),

                // Menu Grid
                Row(
                  children: [
                    Expanded(
                        child: _buildGridMenu("Misi Saya", "${globalMissions.length} Total", Icons.track_changes, Colors.orange.shade100, Colors.orange, () {
                          onNavigate(1);
                        })),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _buildGridMenu("Komunitas", "Gabung Chat", Icons.chat_bubble_outline, Colors.lightBlue.shade100, Colors.lightBlue, () {
                          onNavigate(3);
                        })),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImpactStat(String value, String label, IconData icon) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGridMenu(String title, String subtitle, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}