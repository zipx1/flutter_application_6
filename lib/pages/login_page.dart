import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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

  // Email/Password
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

  // Google Sign-In: ใช้ Firebase Auth ตรง ๆ (ไม่ต้องใช้แพ็กเกจ google_sign_in)
  Future<void> _loginWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // มือถือ (Android/iOS) ใช้ API ใหม่นี้ได้เลย
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ล็อกอินเข้าสู่ระบบ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text('เข้าสู่ระบบด้วย Google'),
                        onPressed: _busy ? null : _loginWithGoogle,
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('หรือเข้าสู่ระบบด้วยอีเมล'),
                    const SizedBox(height: 12),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtl,
                            decoration: const InputDecoration(
                              labelText: 'อีเมล',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'กรอกอีเมล' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passCtl,
                            decoration: const InputDecoration(
                              labelText: 'รหัสผ่าน',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'กรอกรหัสผ่าน' : null,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _loginEmail,
                              child: _busy
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('ล็อกอิน'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.pushReplacementNamed(context, '/register'),
                      child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
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
