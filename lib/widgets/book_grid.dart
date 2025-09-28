import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_required_dialog.dart';

class BookGrid extends StatefulWidget {
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

  @override
  State<BookGrid> createState() => _BookGridState();
}

class _BookGridState extends State<BookGrid> {
  bool isFavorite = false;
  bool isInCart = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _checkInCart();
  }

  double _priceAsDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  // ---------- Toast (SnackBar ลอย) ----------
  void _toast(BuildContext context, String msg,
      {Color? color, IconData? icon, int seconds = 2}) {
    final bar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(msg)),
        ],
      ),
      duration: Duration(seconds: seconds),
      backgroundColor: color ?? Colors.black87,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(bar);
  }

  // ---------- ตรวจสถานะ Favorite ----------
  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.bookId)
        .get();
    if (mounted) setState(() => isFavorite = doc.exists);
  }

  // ---------- ตรวจสถานะในตะกร้า ----------
  Future<void> _checkInCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(widget.bookId)
        .get();
    if (mounted) setState(() => isInCart = doc.exists);
  }

  // ---------- Toggle Favorite ----------
  Future<void> _toggleFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await showDialog(context: context, builder: (_) => const LoginRequiredDialog());
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.bookId);

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
      if (!mounted) return;
      setState(() => isFavorite = false);
      _toast(context, 'ลบออกจากรายการโปรดแล้ว',
          color: Colors.redAccent, icon: Icons.favorite_border);
    } else {
      // ✅ เก็บข้อมูลให้ครบ เพื่อให้หน้า favorites แสดงได้เลย
      await favRef.set({
        'title': widget.title,
        'price': _priceAsDouble(widget.price),
        'coverUrl': widget.coverUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => isFavorite = true);
      _toast(context, 'เพิ่มในรายการโปรดแล้ว',
          color: const Color.fromARGB(255, 0, 0, 0), icon: Icons.favorite);
    }
  }

  // ---------- เพิ่มลงตะกร้า (ใช้ Transaction) ----------
  Future<void> _onAddToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await showDialog(context: context, builder: (_) => const LoginRequiredDialog());
      return;
    }

    final itemRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(widget.bookId);

    bool existed = false; // ✅ จำสถานะก่อนอัปเดต เพื่อใช้แสดงข้อความให้ถูก
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(itemRef);
        existed = snap.exists;

        if (existed) {
          final currentQty = (snap.data()?['qty'] is num)
              ? (snap.data()!['qty'] as num).toInt()
              : 0;
          tx.update(itemRef, {
            'qty': currentQty + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(itemRef, {
            'title': widget.title,
            'price': _priceAsDouble(widget.price),
            'coverUrl': widget.coverUrl,
            'qty': 1,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (!mounted) return;
      setState(() => isInCart = true);
      _toast(
        context,
        existed ? 'เพิ่มจำนวน +1' : 'เพิ่มลงตะกร้าแล้ว',
        color: existed ? Colors.orange : Colors.indigo,
        icon: Icons.add_shopping_cart,
      );
    } catch (e) {
      if (!mounted) return;
      _toast(context, 'เพิ่มลงตะกร้าไม่สำเร็จ',
          color: Colors.redAccent, icon: Icons.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceValue = _priceAsDouble(widget.price);
    // 💡 ดึงสีข้อความหลักจากธีม
    final bodyTextColor = Theme.of(context).textTheme.bodyLarge?.color; 

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // ใช้สีขอบที่เข้ากับธีม
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1), 
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/bookDetail', arguments: widget.bookId),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ปก
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),

            // ชื่อ (💡 แก้ไข: ใช้ bodyTextColor)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 14,
                  color: bodyTextColor, // 💡 ใช้สีที่เปลี่ยนตามธีม
                ),
              ),
            ),

            // ราคา (สีเขียวปกติมักจะอ่านได้ทั้งสองธีม)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '฿${priceValue.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),

            // ปุ่ม
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  // ถูกใจ
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                        side: BorderSide(
                          color: isFavorite 
                              ? Colors.redAccent 
                              : Theme.of(context).dividerColor, // 💡 ใช้สีที่เปลี่ยนตามธีม
                        ),
                      ),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        
                        color: isFavorite 
                            ? Colors.redAccent
                            : bodyTextColor, // 💡 ใช้สีที่เปลี่ยนตามธีม
                        size: 18,
                      ),
                      label: Text(
                        isFavorite ? 'ถูกใจแล้ว' : 'ถูกใจ',
                        style: TextStyle(
                          color: isFavorite 
                              ? Colors.redAccent 
                              : bodyTextColor, // 💡 ใช้สีที่เปลี่ยนตามธีม
                        ),
                      ),
                      onPressed: () => _toggleFavorite(context),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ตะกร้า
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                        backgroundColor: isInCart ? Colors.orange : Theme.of(context).colorScheme.primary, // ใช้สี primary ของธีม
                      ),
                      icon: Icon(
                        isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                        size: 18,
                      ),
                      label: Text(isInCart ? 'อยู่ในตะกร้าแล้ว' : 'ใส่ตะกร้า'),
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
}