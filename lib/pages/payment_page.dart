import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repos/cart_repo.dart';
import '../repos/orders_repo.dart'; // ถ้ามี (ตามที่คุณเคยใช้); ถ้าไม่มีคอมเมนต์ออก

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

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
            appBar: AppBar(title: const Text('ชำระเงิน')),
            body: Center(
              child: FilledButton(
                onPressed: () async => FirebaseAuth.instance.signInAnonymously(),
                child: const Text('เข้าใช้งานแบบ Guest'),
              ),
            ),
          );
        }

        final uid = user.uid;
        final cartRepo = CartRepo(uid);
        final orderRepo = OrdersRepo(uid); // ถ้าไม่มีไฟล์นี้ ให้ลบบรรทัดนี้และส่วน checkout ด้านล่าง

        return Scaffold(
          appBar: AppBar(title: const Text('ชำระเงิน')),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: cartRepo.itemsStream(),
            builder: (_, snap) {
              if (!snap.hasData) {
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

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const ListTile(
                      title: Text('วิธีชำระเงิน'),
                      subtitle: Text('โอน/บัตร (mock)'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ยอดชำระรวม',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${total.toStringAsFixed(0)} ฿'),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: items.isEmpty
                            ? null
                            : () async {
                                try {
                                  final prof = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .get();
                                  final data = prof.data() ?? <String, dynamic>{};
                                  final address =
                                      (data['address'] ?? '') as String;

                                  // ถ้ามี OrdersRepo ใช้บรรทัดนี้:
                                  await orderRepo.checkout(items, address);

                                  // ถ้าไม่มี OrdersRepo: ให้ล้างตะกร้าแทน (ตัวอย่าง)
                                  // for (final it in items) {
                                  //   await cartRepo.remove((it['id'] ?? '') as String);
                                  // }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('ชำระเงินสำเร็จ!')),
                                    );
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/home',
                                      (_) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('ผิดพลาด: $e')),
                                    );
                                  }
                                }
                              },
                        child: const Text('ชำระเงิน'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
