import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesRepo {
  final String uid;
  FavoritesRepo(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites');

  Stream<Set<String>> idsStream() {
    return _col.snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  Future<void> toggle(String bookId, bool isFav) async {
    final ref = _col.doc(bookId);
    if (isFav) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }
}
