import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Peringkat Teman", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Langkah 1: Ambil daftar 'following' dari user yang sedang login
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          List followingList = userData['following'] ?? [];

          // Tambahkan diri sendiri ke daftar agar bisa membandingkan peringkat
          List idsToSearch = List.from(followingList);
          idsToSearch.add(currentUid);

          if (followingList.isEmpty) {
            return const Center(
              child: Text("Belum ada teman yang diikuti.\nCari teman dan lihat peringkat mereka di sini!",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            // Langkah 2: Ambil data user yang ID-nya ada di daftar 'following'
            // Diurutkan berdasarkan poin terbanyak
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: idsToSearch)
                .orderBy('points', descending: true)
                .snapshots(),
            builder: (context, leaderboardSnapshot) {
              if (!leaderboardSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              var users = leaderboardSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var user = users[index].data() as Map<String, dynamic>;
                  bool isMe = users[index].id == currentUid;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isMe ? Colors.green.shade200 : Colors.transparent),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRankColor(index),
                        child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        user['name'] + (isMe ? " (Saya)" : ""),
                        style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text("@${user['username']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${user['points']} Poin",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Helper untuk warna peringkat 1, 2, dan 3
  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // Emas
    if (index == 1) return const Color(0xFFC0C0C0); // Perak
    if (index == 2) return const Color(0xFFCD7F32); // Perunggu
    return const Color(0xFF2E7D32); // Hijau Standar
  }
}