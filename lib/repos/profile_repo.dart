import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileRepo {
  final _db = FirebaseFirestore.instance;
  final String uid;
  ProfileRepo(this.uid);

  Stream<Map<String, dynamic>?> profileStream() =>
      _db.collection('users').doc(uid).snapshots().map((d) => d.data());

  Future<void> saveAddress(String address) =>
      _db.collection('users').doc(uid).set({'address': address, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}
