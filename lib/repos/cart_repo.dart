import 'package:cloud_firestore/cloud_firestore.dart';

class CartRepo {
  final String uid;
  late final CollectionReference<Map<String, dynamic>> _itemsCol;

  CartRepo(this.uid) {
    _itemsCol = FirebaseFirestore.instance
        .collection('carts')
        .doc(uid)
        .collection('items');
  }

  Stream<List<Map<String, dynamic>>> itemsStream() {
    return _itemsCol.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'title': (d['title'] ?? '').toString(),
          'coverUrl': (d['coverUrl'] ?? '').toString(),
          'price': d['price'] is num
              ? (d['price'] as num).toDouble()
              : double.tryParse('${d['price']}') ?? 0.0,
          'qty': d['qty'] is num
              ? (d['qty'] as num).toInt()
              : int.tryParse('${d['qty']}') ?? 0,
        };
      }).toList();
    });
  }

  Future<void> changeQty(String id, int newQty) async {
    await _itemsCol.doc(id).update({
      'qty': newQty,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String id) async {
    await _itemsCol.doc(id).delete();
  }
}
