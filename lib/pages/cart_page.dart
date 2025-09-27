import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repos/cart_repo.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

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
            appBar: AppBar(title: const Text('ตะกร้า')),
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
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

              final total = items.fold<double>(
                0,
                (s, it) =>
                    s +
                    (((it['price'] as num?) ?? 0).toDouble() *
                        (((it['qty'] as num?) ?? 0).toDouble())),
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
                              final id = (it['id'] ?? '') as String;
                              final title = (it['title'] ?? '') as String;
                              final price =
                                  ((it['price'] as num?) ?? 0).toDouble();
                              final qty = ((it['qty'] as num?) ?? 0).toInt();
                              final line = price * qty;
                              return ListTile(
                                leading: const Icon(Icons.book_outlined),
                                title: Text(title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    '${price.toStringAsFixed(0)} ฿ x $qty = ${line.toStringAsFixed(0)} ฿'),
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
                                          } else {
                                            await repo.changeQty(id, newQty);
                                          }
                                        },
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text('$qty'),
                                      IconButton(
                                        tooltip: 'เพิ่มจำนวน',
                                        onPressed: () async =>
                                            repo.changeQty(id, qty + 1),
                                        icon: const Icon(Icons.add),
                                      ),
                                      IconButton(
                                        tooltip: 'ลบออก',
                                        onPressed: () => repo.remove(id),
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
                            Text('${total.toStringAsFixed(0)} ฿'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: items.isEmpty
                                ? null
                                : () => Navigator.pushNamed(context, '/payment'),
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
