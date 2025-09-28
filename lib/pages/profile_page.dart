import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _working = false;

  Future<void> _editName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ctrl = TextEditingController(text: user.displayName ?? '');
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขชื่อแสดง'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(
              hintText: 'พิมพ์ชื่อใหม่...',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, ctrl.text.trim());
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (newName == null) return;

    setState(() => _working = true);
    try {
      await user.updateDisplayName(newName);
      await user.reload();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            {
              'displayName': newName,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปเดตชื่อแล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปเดตชื่อไม่สำเร็จ: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลของฉัน'),
        backgroundColor: const Color.fromARGB(255, 255, 204, 0),
      ),
      body: user == null
          ? Center(
              child: FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('เข้าสู่ระบบ'),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color.fromARGB(255, 255, 230, 0),
                        child: const Icon(Icons.person, color: Color.fromARGB(255, 255, 255, 255), size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.displayName ?? 'ไม่ระบุชื่อ',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: _working ? null : _editName,
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('แก้ไขชื่อ'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(user.email ?? '-'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    'ที่อยู่จัดส่ง',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // อ่าน defaultAddressId จาก users/{uid} แล้วแสดงรายละเอียด
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, userSnap) {
                      if (userSnap.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: LinearProgressIndicator(),
                        );
                      }
                      final userData = userSnap.data?.data() ?? {};
                      final defaultId = (userData['defaultAddressId'] ?? '').toString();

                      if (defaultId.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.location_on_outlined),
                              title: Text('— ยังไม่มีที่อยู่หลัก —'),
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add_location_alt),
                                  label: const Text('เพิ่มที่อยู่ใหม่'),
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/add_address'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('เลือก/แก้ไขที่อยู่'),
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/select_address'),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      final addrRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('addresses')
                          .doc(defaultId);

                      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: addrRef.snapshots(),
                        builder: (context, addrSnap) {
                          final d = addrSnap.data?.data();
                          final name = (d?['fullName'] ?? '').toString();
                          final phone = (d?['phone'] ?? '').toString();
                          final line1 = (d?['line1'] ?? '').toString();
                          final line2 = (d?['line2'] ?? '').toString();
                          final province = (d?['province'] ?? '').toString();
                          final postcode = (d?['postcode'] ?? '').toString();

                          final addressText = (d == null)
                              ? '— ไม่พบรายละเอียดที่อยู่ —'
                              : [
                                  if (name.isNotEmpty) name,
                                  if (phone.isNotEmpty) phone,
                                  if (line1.isNotEmpty) line1,
                                  if (line2.isNotEmpty) line2,
                                  if (province.isNotEmpty || postcode.isNotEmpty)
                                    '$province $postcode',
                                ]
                                  .where((e) => e.trim().isNotEmpty)
                                  .join(' • ');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(
                                  addressText,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.add_location_alt),
                                    label: const Text('เพิ่มที่อยู่ใหม่'),
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/add_address'),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.location_on),
                                    label: const Text('เลือก/แก้ไขที่อยู่'),
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/select_address'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}