import 'package:cloud_firestore/cloud_firestore.dart';

class AddressRepo {
  AddressRepo(this.uid);
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses');

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// สตรีมรายการที่อยู่ทั้งหมด (ใหม่สุดก่อน)
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> addressesStream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs);
  }

  /// เพิ่มที่อยู่ใหม่
  Future<String> addAddress(Map<String, dynamic> data) async {
    final now = FieldValue.serverTimestamp();

    final doc = await _col.add({
      ...data,
      'createdAt': now,
      'updatedAt': now,
    });

    // ตั้ง default ให้ตัวแรกอัตโนมัติถ้ายังไม่มี
    final userSnap = await _userDoc.get();
    final hasDefault =
        (userSnap.data()?['defaultAddressId'] ?? '').toString().isNotEmpty;

    if (!hasDefault) {
      await _userDoc.set(
        {'defaultAddressId': doc.id, 'updatedAt': now},
        SetOptions(merge: true),
      );
    }
    return doc.id;
  }

  /// ลบที่อยู่ (ถ้าลบตัวที่เป็น default จะย้าย default ไปตัวอื่นถ้ามี)
  Future<void> removeAddress(String addressId) async {
    // อ่าน default ปัจจุบัน
    final userSnap = await _userDoc.get();
    final currentDefault =
        (userSnap.data()?['defaultAddressId'] ?? '').toString();

    // ลบเอกสารที่อยู่
    await _col.doc(addressId).delete();

    // ถ้าลบตัวที่เป็น default -> เลือกตัวใหม่ให้ (ถ้ามีเหลือ)
    if (currentDefault == addressId) {
      // หาเอกสารอื่นที่เหลืออยู่สัก 1 ตัว (ข้าม id ที่ลบไปแล้ว)
      final others = await _col
          .where(FieldPath.documentId, isNotEqualTo: addressId)
          .limit(1)
          .get();

      final nextId = others.docs.isEmpty ? '' : others.docs.first.id;

      await _userDoc.set(
        {
          'defaultAddressId': nextId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  /// ตั้งที่อยู่นี้ให้เป็นค่าเริ่มต้น
  Future<void> setDefault(String addressId) async {
    await _userDoc.set(
      {
        'defaultAddressId': addressId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
