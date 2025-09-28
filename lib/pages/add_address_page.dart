import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repos/address_repo.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _province = TextEditingController();
  final _postcode = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _province.dispose();
    _postcode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await AddressRepo(user.uid).addAddress({
        'fullName': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'line1': _line1.text.trim(),
        'line2': _line2.text.trim(),
        'province': _province.text.trim(),
        'postcode': _postcode.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มที่อยู่แล้ว'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context); // กลับ
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มที่อยู่ใหม่')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'ชื่อผู้รับ'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกชื่อผู้รับ' : null,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'เบอร์โทร'),
              ),
              TextFormField(
                controller: _line1,
                decoration: const InputDecoration(labelText: 'ที่อยู่ (บรรทัด 1)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกที่อยู่' : null,
              ),
              TextFormField(
                controller: _line2,
                decoration: const InputDecoration(labelText: 'ที่อยู่ (บรรทัด 2)'),
              ),
              TextFormField(
                controller: _province,
                decoration: const InputDecoration(labelText: 'จังหวัด'),
              ),
              TextFormField(
                controller: _postcode,
                decoration: const InputDecoration(labelText: 'รหัสไปรษณีย์'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('บันทึก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
