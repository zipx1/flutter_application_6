import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_required_dialog.dart';

class BookGrid extends StatelessWidget {
  final String bookId;
  final String title;
  final dynamic price;
  final String coverUrl;

  const BookGrid({
    super.key,
    required this.bookId,
    required this.title,
    required this.price,
    required this.coverUrl,
  });

  double _priceAsDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final priceValue = _priceAsDouble(price);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/bookDetail', arguments: bookId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ รูปปกเต็มพื้นที่การ์ด (ครอบเต็มแบบ cover)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),

            // ชื่อหนังสือ
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            // ราคา
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '฿${priceValue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),

            // ปุ่ม “ถูกใจ” และ “ใส่ตะกร้า”
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.favorite_border, size: 18),
                      label: const Text('ถูกใจ'),
                      onPressed: () => _onFavorite(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('ใส่ตะกร้า'),
                      onPressed: () => _onAddToCart(context),
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

  // ❤️ ฟังก์ชันบันทึกรายการโปรด
  Future<void> _onFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await showDialog(
        context: context,
        builder: (_) => const LoginRequiredDialog(),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(bookId)
        .set({'createdAt': FieldValue.serverTimestamp()});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกรายการโปรดแล้ว')),
      );
    }
  }

  // 🛒 ฟังก์ชันเพิ่มลงตะกร้า
  Future<void> _onAddToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await showDialog(
        context: context,
        builder: (_) => const LoginRequiredDialog(),
      );
      return;
    }

    final ref = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(bookId);

    await ref.set({
      'title': title,
      'price': _priceAsDouble(price),
      'coverUrl': coverUrl,
      'qty': FieldValue.increment(1),
    }, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')),
      );
    }
  }
}
