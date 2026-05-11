import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'leaderboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Fungsi untuk menampilkan pop-up ganti username
  void _showEditUsernameDialog(BuildContext context, String currentUsername) {
    TextEditingController usernameController = TextEditingController(text: currentUsername);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        // Menggunakan StatefulBuilder agar pop-up bisa memuat status loading
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Ganti Username", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: "Username Baru",
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                isLoading
                    ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: CircularProgressIndicator(color: Color(0xFF66BB6A)),
                )
                    : ElevatedButton(
                  onPressed: () async {
                    String newUsername = usernameController.text.trim().toLowerCase();

                    // Cegah save kalau kosong atau tidak ada perubahan
                    if (newUsername.isEmpty || newUsername == currentUsername) return;

                    setState(() => isLoading = true);

                    try {
                      // 1. Cek apakah username sudah ada di database
                      var checkQuery = await FirebaseFirestore.instance
                          .collection('users')
                          .where('username', isEqualTo: newUsername)
                          .get();

                      if (checkQuery.docs.isNotEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Username sudah digunakan, cari yang lain ya!"), backgroundColor: Colors.red),
                          );
                        }
                        setState(() => isLoading = false);
                        return;
                      }

                      // 2. Update username di Firestore
                      await FirebaseFirestore.instance.collection('users').doc(uid).update({
                        'username': newUsername,
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // Tutup pop-up
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Username berhasil diubah!"), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Terjadi kesalahan."), backgroundColor: Colors.red),
                        );
                      }
                      setState(() => isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(context),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? "Eco Warrior";
          String username = userData['username'] ?? "username";
          int points = userData['points'] ?? 0;
          List followers = userData['followers'] ?? [];
          List following = userData['following'] ?? [];
          List interests = userData['interests'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar & Name Section
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF66BB6A),
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                // Username Row dengan tombol Edit
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("@$username", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditUsernameDialog(context, username),
                      child: const Icon(Icons.edit, size: 16, color: Color(0xFF66BB6A)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Followers", followers.length.toString()),
                    _buildStatItem("Following", following.length.toString()),
                    _buildStatItem("Eco Points", points.toString()),
                  ],
                ),
                const SizedBox(height: 32),

                // Leaderboard Tile
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardPage())),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.emoji_events_outlined, color: Colors.white, size: 30),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Friends Leaderboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("See how you rank among friends", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Interests Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Environmental Interests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((item) => Chip(
                      label: Text(item.toString(), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFFE8F5E9),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 40),

                // Achievement Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Color(0xFF66BB6A), size: 30),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Membership Level", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(points > 100 ? "Silver Guardian" : "Green Member", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Out?"),
        content: const Text("Are you sure you want to end your eco-session today?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (r) => false);
              }
            },
            child: const Text("Yes, Log Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}