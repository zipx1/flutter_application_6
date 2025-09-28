import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    final name = _usernameCtl.text.trim();
    final email = _emailCtl.text.trim();
    final pass = _passCtl.text;

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);

      final user = cred.user!;
      await user.updateDisplayName(name);
      await user.reload();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': name,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _toast('สมัครสมาชิกสำเร็จ');
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 10,
                color: Colors.black87,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 64, color: Colors.yellow),
                      const SizedBox(height: 12),
                      const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameCtl,
                              decoration: InputDecoration(
                                labelText: 'ชื่อผู้ใช้',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon:
                                    const Icon(Icons.person_outline, color: Colors.yellow),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return 'กรอกชื่อผู้ใช้';
                                if (t.length < 3) return 'อย่างน้อย 3 ตัวอักษร';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailCtl,
                              decoration: InputDecoration(
                                labelText: 'อีเมล',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon:
                                    const Icon(Icons.email_outlined, color: Colors.yellow),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'กรอกอีเมล' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passCtl,
                              decoration: InputDecoration(
                                labelText: 'รหัสผ่าน (≥6)',
                                labelStyle: const TextStyle(color: Colors.white70),
                                prefixIcon:
                                    const Icon(Icons.lock_outline, color: Colors.yellow),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color.fromARGB(255, 255, 255, 255)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'กรอกรหัสผ่าน';
                                if (v.length < 6) return 'อย่างน้อย 6 ตัวอักษร';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _busy ? null : _register,
                                child: _busy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text(
                                        'สมัครสมาชิก',
                                        style: TextStyle(fontWeight: FontWeight.bold),
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
                            : () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          'มีบัญชีแล้ว? เข้าสู่ระบบ',
                          style: TextStyle(color: Colors.yellow),
                        ),
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