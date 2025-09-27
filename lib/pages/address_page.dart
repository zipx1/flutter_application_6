import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repos/profile_repo.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});
  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _ctl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = ProfileRepo(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('ที่อยู่จัดส่ง')),
      body: StreamBuilder(
        stream: repo.profileStream(),
        builder: (_, snap) {
          final address = (snap.data ?? const {})['address'] ?? '';
          _ctl.value = TextEditingValue(text: address, selection: TextSelection.collapsed(offset: address.length));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(controller: _ctl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'ที่อยู่')),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async { await repo.saveAddress(_ctl.text.trim()); if (context.mounted) Navigator.pushNamed(context, '/payment'); },
                  child: const Text('ถัดไป'),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
