import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repos/cart_repo.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

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
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(bar);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnap.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: const Text('ตะกร้า'),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('ไปหน้าเข้าสู่ระบบ'),
              ),
            ),
          );
        }

        final repo = CartRepo(user.uid);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('ตะกร้า'),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
          ),

          // ===== เนื้อหา =====
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.itemsStream(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data ?? const <Map<String, dynamic>>[];

              // รวมยอด: ถ้า qty ไม่มี/เป็น 0 ให้ถือเป็น 1
              final total = items.fold<double>(
                0,
                (s, it) {
                  final price = ((it['price'] as num?) ?? 0).toDouble();
                  final qty = (((it['qty'] as num?) ?? 1).toDouble());
                  return s + (price * qty);
                },
              );

              if (items.isEmpty) {
                // ===== Empty state กลางจอ =====
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text('ตะกร้ายังว่างอยู่',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16)),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => Navigator.pushNamed(context, '/home'),
                          child: const Text('ไปเลือกหนังสือ'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ===== มีสินค้า: แสดงรายการ + สรุปด้านล่างแบบ sticky =====
              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = items[i];
                        final id = (it['id'] ?? '').toString();
                        final title = (it['title'] ?? '').toString();
                        final coverUrl = (it['coverUrl'] ?? '').toString();
                        final price =
                            ((it['price'] as num?) ?? 0).toDouble();
                        final qty = ((it['qty'] as num?) ?? 1).toInt();
                        final line = price * qty;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: coverUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: coverUrl,
                                      width: 50,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        width: 50,
                                        height: 70,
                                        color: Colors.grey[200],
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : const Icon(Icons.menu_book_outlined, size: 32),
                            ),
                            title: Text(
                              title.isEmpty ? 'ไม่มีชื่อ' : title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '฿${price.toStringAsFixed(0)} x $qty = ฿${line.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            trailing: SizedBox(
                              width: 170,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'ลดจำนวน',
                                    onPressed: () async {
                                      final newQty = qty - 1;
                                      if (newQty <= 0) {
                                        await repo.remove(id);
                                        _toast(context, 'นำออกจากตะกร้าแล้ว',
                                            color: Colors.redAccent,
                                            icon: Icons.delete_outline);
                                      } else {
                                        await repo.changeQty(id, newQty);
                                        _toast(context, 'ลดจำนวน -1',
                                            color: Colors.orange,
                                            icon: Icons.remove);
                                      }
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('$qty'),
                                  IconButton(
                                    tooltip: 'เพิ่มจำนวน',
                                    onPressed: () async {
                                      await repo.changeQty(id, qty + 1);
                                      _toast(context, 'เพิ่มจำนวน +1',
                                          color: Colors.indigo,
                                          icon: Icons.add_circle_outline);
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  IconButton(
                                    tooltip: 'ลบออก',
                                    onPressed: () async {
                                      await repo.remove(id);
                                      _toast(context, 'นำออกจากตะกร้าแล้ว',
                                          color: Colors.redAccent,
                                          icon: Icons.delete_outline);
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ===== สรุปยอด + ปุ่มไปชำระเงิน (sticky) =====
                  SafeArea(
                    top: false,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('รวมทั้งหมด',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('฿${total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/payment',
                                  arguments: {
                                    'total': total,
                                    'items': items.map((e) => {
                                          'bookId': e['bookId'] ?? e['id'],
                                          'title': e['title'],
                                          'price': e['price'],
                                          'qty': e['qty'] ?? 1,
                                          'coverUrl': e['coverUrl'],
                                        }).toList(),
                                  },
                                );
                              },
                              child: const Text('ซื้อสินค้า'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
