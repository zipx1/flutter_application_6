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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ตะกร้า')),
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
          appBar: AppBar(title: const Text('ตะกร้า')),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.itemsStream(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data ?? const <Map<String, dynamic>>[];

              // ✅ รวมยอด: ถ้า qty ไม่มี/เป็น 0 ให้ถือเป็น 1 เพื่อกันยอดรวมเป็น 0
              final total = items.fold<double>(
                0,
                (s, it) {
                  final price = ((it['price'] as num?) ?? 0).toDouble();
                  final qty =
                      (((it['qty'] as num?) ?? 1).toDouble()); // default 1
                  return s + (price * qty);
                },
              );

              return Column(
                children: [
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('ตะกร้ายังว่างอยู่'))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final it = items[i];
                              final id = (it['id'] ?? '').toString();
                              final title = (it['title'] ?? '').toString();
                              final coverUrl = (it['coverUrl'] ?? '').toString();
                              final price =
                                  ((it['price'] as num?) ?? 0).toDouble();
                              final qty = ((it['qty'] as num?) ?? 1).toInt();
                              final line = price * qty;

                              return ListTile(
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
                                      : const Icon(Icons.book_outlined),
                                ),
                                title: Text(
                                  title.isEmpty ? 'ไม่มีชื่อ' : title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '฿${price.toStringAsFixed(0)} x $qty = ฿${line.toStringAsFixed(0)}',
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
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text('$qty'),
                                      IconButton(
                                        tooltip: 'เพิ่มจำนวน',
                                        onPressed: () async {
                                          await repo.changeQty(id, qty + 1);
                                          _toast(context, 'เพิ่มจำนวน +1',
                                              color: Colors.indigo,
                                              icon: Icons.add);
                                        },
                                        icon: const Icon(Icons.add),
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
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('รวมทั้งหมด',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('฿${total.toStringAsFixed(0)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: items.isEmpty
                                ? null
                                : () {
                                    // ✅ ส่ง total + items ไปหน้า /payment
                                    Navigator.pushNamed(
                                      context,
                                      '/payment',
                                      arguments: {
                                        'total': total, // ส่งยอดรวม (double)
                                        'items': items.map((e) => {
                                              // ส่งฟิลด์ที่จำเป็น (หน้า payment รองรับทุกชนิดอยู่แล้ว)
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
                ],
              );
            },
          ),
        );
      },
    );
  }
}
