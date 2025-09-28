import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  /// ถ้าไม่ส่งหรือเป็น 0 จะคำนวณจาก items ให้เอง
  final double totalPrice;
  /// [{bookId,title,price,qty}, ...] ชนิด price/qty จะเป็น int/double/string ก็ได้
  final List<Map<String, dynamic>> items;

  const PaymentPage({
    super.key,
    required this.totalPrice,
    this.items = const [],
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _paymentMethod = 'transfer';
  final _noteCtrl = TextEditingController();
  bool _placing = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ---------------- Helpers: number parsing & totals ----------------
  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    final cleaned = (v?.toString() ?? '').replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(cleaned) ?? fallback;
  }

  double _calcItemsTotal() {
    double sum = 0;
    for (final it in widget.items) {
      final price = _toDouble(it['price']);
      final qty = _toDouble(it['qty'] ?? it['quantity'] ?? 1, fallback: 1);
      sum += price * qty;
    }
    return sum;
  }

  /// ใช้ totalPrice ถ้ามากกว่า 0 ไม่งั้นคำนวณจาก items
  double get _displayTotal =>
      (widget.totalPrice > 0) ? widget.totalPrice : _calcItemsTotal();

  // ---------------- Firestore streams ----------------
  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDoc() {
    if (_uid == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('users').doc(_uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> _defaultAddressStream() {
    if (_uid == null) return Stream.value(null);
    final userRef = FirebaseFirestore.instance.collection('users').doc(_uid);
    return userRef.snapshots().asyncMap((userSnap) async {
      final data = userSnap.data();
      final defaultId = data?['defaultAddressId'] as String?;
      if (defaultId != null && defaultId.isNotEmpty) {
        return userRef.collection('addresses').doc(defaultId).get();
      } else {
        final q = await userRef
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) return q.docs.first;
      }
      return null;
    });
  }

  // ---------------- Place order ----------------
  Future<void> _placeOrder(
    Map<String, dynamic> addressData,
    String addressId,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _placing = true);
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final ordersRef = userRef.collection('orders');

      await ordersRef.add({
        'total': _displayTotal, // ✅ ใช้ยอดที่คำนวณแล้ว
        'method': _paymentMethod,
        'status': 'pending',
        'note': _noteCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'shippingAddress': {
          'id': addressId,
          'fullName': addressData['fullName'],
          'phone': addressData['phone'],
          'line1': addressData['line1'],
          'line2': addressData['line2'],
          'province': addressData['province'],
          'postcode': addressData['postcode'],
        },
        'items': widget.items,
      });

      if (!mounted) return;

      // ✅ ขอบคุณที่ชำระเงิน (popup กลางจอ)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('ขอบคุณที่ชำระเงิน'),
          content: const Text('เราได้รับคำสั่งซื้อของคุณแล้ว'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/payment_success', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สั่งซื้อไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ชำระเงิน')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('ไปหน้าเข้าสู่ระบบ'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDoc(),
        builder: (context, _) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            stream: _defaultAddressStream(),
            builder: (context, addrSnap) {
              final hasAddr =
                  addrSnap.hasData && addrSnap.data != null && addrSnap.data!.exists;
              final addrData = hasAddr ? addrSnap.data!.data()! : null;
              final addrId = hasAddr ? addrSnap.data!.id : null;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ====== ที่อยู่จัดส่ง ======
                  Text('ที่อยู่จัดส่ง',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: hasAddr
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${addrData!['fullName']} • ${addrData['phone']}',
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text('${addrData['line1']} ${addrData['line2']}'),
                                Text('${addrData['province']} ${addrData['postcode']}'),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/select_address'),
                                    icon: const Icon(Icons.edit_location_alt),
                                    label: const Text('เปลี่ยนที่อยู่'),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ยังไม่ได้เพิ่มที่อยู่จัดส่ง'),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/add_address'),
                                  icon: const Icon(Icons.add_location_alt),
                                  label: const Text('เพิ่มที่อยู่'),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ====== วิธีชำระเงิน ======
                  Text('วิธีชำระเงิน',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'transfer',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                          title: const Text('โอน/บัตร (mock)'),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          value: 'cod',
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                          title: const Text('เก็บเงินปลายทาง (COD)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ====== หมายเหตุ ======
                  Text('หมายเหตุ (ถ้ามี)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'เช่น จัดส่งช่วงเย็น, ห่อของขวัญ ฯลฯ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ====== สรุปยอด ======
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ยอดชำระรวม',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${_displayTotal.toStringAsFixed(0)} ฿',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ====== ปุ่มยืนยัน ======
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: (!hasAddr || _placing)
                          ? null
                          : () => _placeOrder(addrData!, addrId!),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      child: _placing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('ชำระเงิน'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
