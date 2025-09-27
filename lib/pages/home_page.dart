import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/book_grid.dart';
import '../widgets/custom_top_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final booksStream = FirebaseFirestore.instance
        .collection('books')
        .orderBy('title')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomTopBar(), // ✅ ใช้ TopBar หลังล็อกอินแบบที่คุยกัน
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: booksStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีหนังสือ'));
          }

          final docs = snap.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              // ✅ คำนวณจำนวนคอลัมน์ให้พอดีกับความกว้างหน้าจอ
              const targetCardWidth = 180.0;
              final crossAxisCount =
                  (constraints.maxWidth / targetCardWidth).floor().clamp(2, 6);

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.60, // ✅ สูงพอ ลดโอกาส overflow
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final d = doc.data();

                  return BookGrid(
                    bookId: doc.id,
                    // ✅ กัน type เพี้ยนจาก Firestore (เช่น title เป็น int)
                    title: (d['title'] ?? '').toString(),
                    price: d['price'],            // dynamic ให้ไปแปลงใน BookGrid
                    coverUrl: d['coverUrl'],      // dynamic ให้ไปแปลงใน BookGrid
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
