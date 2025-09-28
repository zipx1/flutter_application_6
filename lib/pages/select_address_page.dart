import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repos/address_repo.dart';

class SelectAddressPage extends StatelessWidget {
  const SelectAddressPage({super.key});

  String _display(Map<String, dynamic> d) {
    final name = (d['fullName'] ?? '').toString().trim();
    final phone = (d['phone'] ?? '').toString().trim();
    final line1 = (d['line1'] ?? '').toString().trim();
    final line2 = (d['line2'] ?? '').toString().trim();
    final province = (d['province'] ?? '').toString().trim();
    final postcode = (d['postcode'] ?? '').toString().trim();

    final head = name.isNotEmpty ? name : (line1.isNotEmpty ? line1 : '— ไม่มีข้อมูล —');
    final details = [
      if (phone.isNotEmpty) phone,
      if (line2.isNotEmpty) line2,
      [province, postcode].where((e) => e.isNotEmpty).join(' ')
    ].where((e) => e.isNotEmpty).join(' • ');

    return details.isNotEmpty ? '$head • $details' : head;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('เลือกที่อยู่จัดส่ง')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('เข้าสู่ระบบ'),
          ),
        ),
      );
    }
    final repo = AddressRepo(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกที่อยู่จัดส่ง')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnap) {
          final defaultId = (userSnap.data?.data()?['defaultAddressId'] ?? '').toString();

          return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: repo.addressesStream(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ยังไม่มีที่อยู่'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('เพิ่มที่อยู่ใหม่'),
                        onPressed: () => Navigator.pushNamed(context, '/add_address'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = docs[i].data();
                  final id = docs[i].id;
                  final isDefault = id == defaultId;

                  return ListTile(
                    leading: Icon(
                      isDefault ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isDefault ? Colors.green : null,
                    ),
                    title: Text(_display(d), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => repo.setDefault(id),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'ลบที่อยู่นี้',
                      onPressed: () => repo.removeAddress(id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_address'),
        label: const Text('เพิ่มที่อยู่'),
        icon: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
