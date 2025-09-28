import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  void _goAfterLogin() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final redirect = args?['redirect'] as String?;
    if (redirect != null && redirect.isNotEmpty) {
      Navigator.pushReplacementNamed(context, redirect);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passCtl.text.trim(),
      );
      if (!mounted) return;
      _goAfterLogin();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? 'ล็อกอินไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
      if (!mounted) return;
      _goAfterLogin();
    } catch (e) {
      if (!mounted) return;
      _toast('Google Sign-In ล้มเหลว: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0), // ✅ ขาวเป็นพื้นหลัง
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.black, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 72, color: Colors.black87),
                    const SizedBox(height: 12),
                    const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 🔹 ปุ่ม Google
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.google,
                            color: Colors.red, size: 22),
                        label: const Text(
                          'เข้าสู่ระบบด้วย Google',
                          style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _busy ? null : _loginWithGoogle,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text('หรือเข้าสู่ระบบด้วยอีเมล',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),

                    // 🔹 ฟอร์มอีเมล/รหัสผ่าน
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtl,
                            decoration: InputDecoration(
                              labelText: 'อีเมล',
                              labelStyle:
                                  const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Colors.black),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.black),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.yellow, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'กรอกอีเมล'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtl,
                            decoration: InputDecoration(
                              labelText: 'รหัสผ่าน',
                              labelStyle:
                                  const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Colors.black),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.black),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.yellow, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'กรอกรหัสผ่าน' : null,
                          ),
                          const SizedBox(height: 20),

                          // 🔹 ปุ่ม Login เหลืองดำ
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _busy ? null : _loginEmail,
                              child: _busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Text(
                                      'ล็อกอิน',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () =>
                              Navigator.pushReplacementNamed(context, '/register'),
                      child: const Text(
                        'ยังไม่มีบัญชี? สมัครสมาชิก',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}