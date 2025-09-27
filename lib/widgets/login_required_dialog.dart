import 'package:flutter/material.dart';

class LoginRequiredDialog extends StatelessWidget {
  const LoginRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Icon(Icons.error_outline, size: 48, color: Colors.orange),
      content: const Text('กรุณาล็อกอินก่อนใช้งานฟังก์ชันนี้ด้วยจ้า'),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/login');
          },
          child: const Text('ล็อกอิน'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
      ],
    );
  }
}
