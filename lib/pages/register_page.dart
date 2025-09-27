import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtl.text.trim(),
        password: _passCtl.text.trim(),
      );

      // ตั้ง displayName = ชื่อผู้ใช้
      await cred.user?.updateDisplayName(_usernameCtl.text.trim());

      if (!mounted) return;
      _toast('สมัครสมาชิกสำเร็จ');
      // ไปหน้าแรก (หรือจะ pushReplacementNamed(context, '/login') ก็ได้)
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(e.message ?? 'สมัครสมาชิกไม่สำเร็จ');
    } catch (e) {
      if (!mounted) return;
      _toast('เกิดข้อผิดพลาด: $e');
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Username
                      TextFormField(
                        controller: _usernameCtl,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ใช้',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'กรอกชื่อผู้ใช้';
                          if (t.length < 3) return 'อย่างน้อย 3 ตัวอักษร';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtl,
                        decoration: const InputDecoration(
                          labelText: 'อีเมล',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'กรอกอีเมล' : null,
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _passCtl,
                        decoration: const InputDecoration(
                          labelText: 'รหัสผ่าน (≥6)',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรอกรหัสผ่าน';
                          if (v.length < 6) return 'อย่างน้อย 6 ตัวอักษร';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _register,
                          child: _busy
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('สมัครสมาชิก'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
