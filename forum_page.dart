import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Data statis untuk kategori
  final List<Map<String, dynamic>> _categories = [
    {'title': 'Vegan Lifestyle', 'members': '2.3k members', 'color': const Color(0xFF66BB6A)},
    {'title': 'Zero Waste', 'members': '1.8k members', 'color': const Color(0xFF4FC3F7)},
    {'title': 'Eco Living', 'members': '3.1k members', 'color': const Color(0xFFFFCA28)},
  ];

  // Fungsi untuk menampilkan Pop-up buat postingan baru
  void _showAddPostDialog() {
    TextEditingController postController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Buat Postingan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: postController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Bagikan perjalanan ramah lingkunganmu hari ini...",
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (postController.text.trim().isEmpty) return;

                    // Ambil nama user saat ini dari Firestore untuk ditampilkan di post
                    var userDoc = await _firestore.collection('users').doc(_currentUid).get();
                    String authorName = userDoc.data()?['name'] ?? "Eco Warrior";

                    // Simpan postingan ke Firestore
                    await _firestore.collection('posts').add({
                      'uid': _currentUid,
                      'authorName': authorName,
                      'content': postController.text.trim(),
                      'likes': [], // Array penyimpan UID yang nge-like
                      'commentCount': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                      'category': 'Eco Living', // Default kategori untuk demo
                    });

                    if (context.mounted) Navigator.pop(context); // Tutup pop-up
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Posting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk menampilkan Pop-up Komentar
  void _showCommentsBottomSheet(BuildContext context, String postId) {
    TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Agar tidak tertutup keyboard
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6, // Tinggi pop-up 60% dari layar
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Komentar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),

                // --- DAFTAR KOMENTAR (StreamBuilder) ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    // Mengambil data dari sub-collection 'comments' milik postingan ini
                    stream: _firestore
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false) // Urutkan dari yang terlama ke terbaru
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF66BB6A)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("Belum ada komentar. Jadilah yang pertama!", style: TextStyle(color: Colors.grey)));
                      }

                      var comments = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var commentData = comments[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF66BB6A),
                                  child: Text(
                                    commentData['authorName'].substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(commentData['authorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text(commentData['text'], style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // --- INPUT KOMENTAR BARU ---
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: "Tulis komentar...",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF66BB6A),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;

                          String text = commentController.text.trim();
                          commentController.clear(); // Bersihkan kolom ketik setelah dikirim

                          // 1. Ambil nama user yang sedang login
                          var userDoc = await _firestore.collection('users').doc(_currentUid).get();
                          String authorName = userDoc.data()?['name'] ?? "Eco Warrior";

                          // 2. Tambah komentar ke Firestore (Sub-collection)
                          await _firestore.collection('posts').doc(postId).collection('comments').add({
                            'uid': _currentUid,
                            'authorName': authorName,
                            'text': text,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          // 3. Update angka 'commentCount' di dokumen post utama (+1)
                          await _firestore.collection('posts').doc(postId).update({
                            'commentCount': FieldValue.increment(1),
                          });
                        },
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi untuk format waktu (contoh: "2h ago")
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    Duration diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER & SEARCH ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Community Forum", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: "Search discussions...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- KATEGORI (Horizontal Scroll) ---
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  var cat = _categories[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: cat['color'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(cat['members'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // --- TRENDING DISCUSSIONS HEADER ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Trending Discussions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("~ View All", style: TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- FEED POSTINGAN (StreamBuilder) ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Mengambil data dari koleksi 'posts' diurutkan dari yang terbaru
                stream: _firestore.collection('posts').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF66BB6A)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Belum ada diskusi. Jadilah yang pertama posting!", style: TextStyle(color: Colors.grey)));
                  }

                  var posts = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index];
                      var data = post.data() as Map<String, dynamic>;

                      List likes = data['likes'] ?? [];
                      bool isLiked = likes.contains(_currentUid); // Cek apakah user sudah nge-like

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Post: Avatar, Nama, Kategori, Waktu
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF66BB6A),
                                  child: Text(data['authorName'].substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['authorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(data['category'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(_formatTime(data['createdAt'] as Timestamp?), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Isi Postingan
                            Text(data['content'], style: const TextStyle(fontSize: 15, height: 1.4)),
                            const SizedBox(height: 15),

                            // Aksi: Like, Comment, View
                            Divider(color: Colors.grey.shade200),
                            Row(
                              children: [
                                // Tombol Like Interaktif
                                GestureDetector(
                                  onTap: () async {
                                    if (isLiked) {
                                      await _firestore.collection('posts').doc(post.id).update({
                                        'likes': FieldValue.arrayRemove([_currentUid])
                                      });
                                    } else {
                                      await _firestore.collection('posts').doc(post.id).update({
                                        'likes': FieldValue.arrayUnion([_currentUid])
                                      });
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 20),
                                      const SizedBox(width: 5),
                                      Text("${likes.length}", style: TextStyle(color: isLiked ? Colors.red : Colors.grey)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),

                                // Tombol Komentar Interaktif
                                GestureDetector(
                                  onTap: () {
                                    _showCommentsBottomSheet(context, post.id);
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 20),
                                      const SizedBox(width: 5),
                                      Text("${data['commentCount']}", style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),

                                const Spacer(), // Mendorong icon member ke pojok kanan
                                const Row(
                                  children: [
                                    Icon(Icons.people_outline, color: Colors.grey, size: 20),
                                    SizedBox(width: 5),
                                    Text("156", style: TextStyle(color: Colors.grey)), // Angka dummy views
                                  ],
                                ),
                              ],
                            )
                          ],
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

      // Tombol Mengambang (FAB) untuk buat post baru
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        backgroundColor: const Color(0xFF66BB6A),
        elevation: 4,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white),
      ),
    );
  }
}