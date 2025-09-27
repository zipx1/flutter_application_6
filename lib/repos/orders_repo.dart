import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersRepo {
  final _db = FirebaseFirestore.instance;
  final String uid;
  OrdersRepo(this.uid);

  Future<void> checkout(List<Map<String, dynamic>> items, String address) async {
    final total = items.fold<double>(0, (s, it) => s + (it['price'] as num).toDouble() * (it['qty'] as num).toInt());
    final orderRef = _db.collection('users').doc(uid).collection('orders').doc();

    await _db.runTransaction((tx) async {
      tx.set(orderRef, {
        'items': items.map((e) => {
          'bookId': e['bookId'], 'title': e['title'], 'price': e['price'], 'qty': e['qty']
        }).toList(),
        'total': total,
        'address': address,
        'status': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final cartCol = _db.collection('users').doc(uid).collection('cart');
      final cartDocs = await cartCol.get();
      for (final d in cartDocs.docs) { tx.delete(d.reference); }
    });
  }
}
