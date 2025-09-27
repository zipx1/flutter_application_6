import 'package:cloud_firestore/cloud_firestore.dart';

class BookRepo {
  final _col = FirebaseFirestore.instance.collection('books');

  Stream<List<Map<String, dynamic>>> booksStream() {
    return _col.snapshots().map((snap) {
      return snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'title': (d['title'] ?? '').toString(),
          'price': (d['price'] is num) ? (d['price'] as num).toDouble() : 0.0,
          'coverUrl': (d['coverUrl'] ?? '').toString(),
          'description': (d['description'] ?? '').toString(),
        };
      }).toList();
    });
  }
}
