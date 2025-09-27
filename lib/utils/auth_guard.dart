import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> ensureLoggedIn(
  BuildContext context, {
  String? redirectAfterLogin,       // '/', '/cart', '/payment', ...
  String loginRouteName = '/login',
  String? reasonMessage,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  // ยังไม่ล็อกอิน หรือเป็น Guest -> ให้ไปล็อกอินจริงก่อน
  if (user == null || user.isAnonymous) {
    if (reasonMessage != null && reasonMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reasonMessage)));
    }
    if (context.mounted) {
      Navigator.pushNamed(
        context,
        loginRouteName,
        arguments: {'redirect': redirectAfterLogin},
      );
    }
    return false;
  }
  return true;
}
