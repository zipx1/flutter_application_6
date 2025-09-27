// lib/pages/book_detail_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookDetailPage extends StatelessWidget {
  final String bookId;                 // ✅ รับตรง ๆ
  const BookDetailPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('ไม่พบหนังสือ'));
          }

          final d = snap.data!.data()!;
          final title = d['title'] ?? '-';
          final price = d['price'];
          final cover = d['coverUrl'] ?? '';
          final desc  = d['description'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cover.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: cover,
                        width: 220,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price is num ? '฿${price.toStringAsFixed(0)}' : price.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    FilledButton(
                      onPressed: () async { await _addToCart(bookId, d, context); },
                      child: const Text('ซื้อ'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('คำอธิบาย', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(desc),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addToCart(String bookId, Map<String, dynamic> book, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนซื้อ')));
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('carts').doc(user.uid)
        .collection('items').doc(bookId);

    await ref.set({
      'title': book['title'] ?? '',
      'price': book['price'] ?? 0,
      'coverUrl': book['coverUrl'] ?? '',
      'qty': FieldValue.increment(1),
    }, SetOptions(merge: true)).catchError((_) async {
      await ref.set({
        'title': book['title'] ?? '',
        'price': book['price'] ?? 0,
        'coverUrl': book['coverUrl'] ?? '',
        'qty': 1,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')));
  }
}
