import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchTerm = "";
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 30, 24, 10),
              child: Text(
                "Cari Teman",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Temukan dan ikuti perjalanan peduli lingkungan mereka.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),

            // --- SEARCH BAR KUSTOM ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Ketik username teman...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchTerm = "";
                        });
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchTerm = val.toLowerCase().trim();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- HASIL PENCARIAN (BODY) ---
            Expanded(
              child: _searchTerm.isEmpty
                  ? _buildEmptyState(
                Icons.person_search_rounded,
                "Mulai Pencarian",
                "Ketik username dengan benar\nuntuk mencari temanmu.",
              )
                  : StreamBuilder<QuerySnapshot>(
                // Mencari user berdasarkan username yang tepat
                stream: _firestore
                    .collection('users')
                    .where('username', isEqualTo: _searchTerm)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(
                      Icons.search_off_rounded,
                      "Tidak Ditemukan",
                      "User dengan username '$_searchTerm' tidak ada. Coba cek kembali ejaannya.",
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var userDoc = snapshot.data!.docs[index];
                      var userData = userDoc.data() as Map<String, dynamic>;
                      String targetUid = userDoc.id;

                      // Supaya tidak bisa follow diri sendiri
                      if (targetUid == _currentUid) {
                        return _buildEmptyState(
                          Icons.waving_hand_rounded,
                          "Hai, itu kamu!",
                          "Kamu tidak bisa mengikuti dirimu sendiri.",
                        );
                      }

                      List followers = userData['followers'] ?? [];
                      bool isFollowing = followers.contains(_currentUid);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: const CircleAvatar(
                            radius: 25,
                            backgroundColor: Color(0xFF66BB6A),
                            child: Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          title: Text(
                            userData['name'] ?? "User",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "@${userData['username']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _toggleFollow(targetUid, isFollowing, userData['name']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.grey.shade100 : const Color(0xFF2E7D32),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              isFollowing ? "Mengikuti" : "Ikuti",
                              style: TextStyle(
                                color: isFollowing ? Colors.black87 : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk Follow/Unfollow
  Future<void> _toggleFollow(String targetUid, bool isFollowing, String targetName) async {
    try {
      if (isFollowing) {
        // Logika Unfollow
        await _firestore.collection('users').doc(_currentUid).update({
          'following': FieldValue.arrayRemove([targetUid])
        });
        await _firestore.collection('users').doc(targetUid).update({
          'followers': FieldValue.arrayRemove([_currentUid])
        });
      } else {
        // Logika Follow
        await _firestore.collection('users').doc(_currentUid).update({
          'following': FieldValue.arrayUnion([targetUid])
        });
        await _firestore.collection('users').doc(targetUid).update({
          'followers': FieldValue.arrayUnion([_currentUid])
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Berhasil mengikuti $targetName!"),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error follow: $e");
    }
  }

  // Widget bantuan untuk menampilkan status kosong yang rapi
  Widget _buildEmptyState(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: const Color(0xFF66BB6A)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 40), // Ruang ekstra di bawah agar posisinya agak ke atas
          ],
        ),
      ),
    );
  }
}