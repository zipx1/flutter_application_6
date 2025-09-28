import 'package:flutter/material.dart';

class LoginRequiredDialog extends StatelessWidget {
  const LoginRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Icon(Icons.error_outline, size: 48, color: Color.fromARGB(255, 255, 152, 0)),
      content: const Text('กรุณาล็อกอินก่อนทำการสั่งซื้อด้วยงั้บ'),
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
