import 'package:cloud_firestore/cloud_firestore.dart';

class CartRepo {
  final String uid;
  CartRepo(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('cart');

  Stream<List<Map<String, dynamic>>> itemsStream() {
    return _col.snapshots().map(
          (s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> add(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    await _col.doc(id).set({
      'title': item['title'],
      'price': item['price'],
      'coverUrl': item['coverUrl'],
      'qty': (item['qty'] ?? 1) as int,
    }, SetOptions(merge: true));
  }

  Future<void> changeQty(String id, int qty) async {
    if (qty <= 0) {
      await remove(id);
    } else {
      await _col.doc(id).update({'qty': qty});
    }
  }

  Future<void> remove(String id) => _col.doc(id).delete();
}
