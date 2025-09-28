import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _fPhone = FocusNode();
  final _fLine1 = FocusNode();
  final _fLine2 = FocusNode();
  final _fProvince = FocusNode();
  final _fPostcode = FocusNode();

  bool _busy = false;
  bool _setAsDefault = true;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _province.dispose();
    _postcode.dispose();

    _fPhone.dispose();
    _fLine1.dispose();
    _fLine2.dispose();
    _fProvince.dispose();
    _fPostcode.dispose();
    super.dispose();
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'กรุณากรอก$label' : null;

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนเพิ่มที่อยู่')),
      );
      return;
    }
    if (!_formKey.currentState!.validate() || _busy) return;

    setState(() => _busy = true);
    try {
      await AddressRepo(user.uid).addAddress({
        'fullName': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'line1': _line1.text.trim(),
        'line2': _line2.text.trim(),
        'province': _province.text.trim(),
        'postcode': _postcode.text.trim(),
        'isDefault': _setAsDefault,
        'createdAt': DateTime.now().toIso8601String(), // เผื่อดูแบบ offline
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกที่อยู่เรียบร้อย'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกไม่สำเร็จ: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  InputDecoration _dec({
    required String label,
    required IconData icon,
    String? hint,
    TextEditingController? controller,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: controller == null || controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'ล้างข้อความ',
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final previewAddress = [
      _line1.text.trim(),
      _line2.text.trim(),
      [_province.text.trim(), _postcode.text.trim()].where((e) => e.isNotEmpty).join(' ')
    ].where((e) => e.isNotEmpty).join('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มที่อยู่ใหม่'),
        backgroundColor: const Color.fromARGB(255, 255, 187, 0),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth >= 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ========== ส่วนข้อมูลผู้รับ ==========
                  _sectionTitle('ข้อมูลผู้รับ'),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _fullName,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        _fPhone.requestFocus(),
                                    decoration: _dec(
                                      label: 'ชื่อผู้รับ',
                                      icon: Icons.person,
                                      controller: _fullName,
                                    ),
                                    validator: (v) => _required(v, 'ชื่อผู้รับ'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 260,
                                  child: TextFormField(
                                    controller: _phone,
                                    focusNode: _fPhone,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        _fLine1.requestFocus(),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: _dec(
                                      label: 'เบอร์โทร (10 หลัก)',
                                      icon: Icons.call,
                                      controller: _phone,
                                    ),
                                    validator: (v) {
                                      final s = v?.trim() ?? '';
                                      if (s.isEmpty) return 'กรุณากรอกเบอร์โทร';
                                      if (s.length != 10) {
                                        return 'เบอร์โทรต้อง 10 หลัก';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                TextFormField(
                                  controller: _fullName,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _fPhone.requestFocus(),
                                  decoration: _dec(
                                    label: 'ชื่อผู้รับ',
                                    icon: Icons.person,
                                    controller: _fullName,
                                  ),
                                  validator: (v) => _required(v, 'ชื่อผู้รับ'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _phone,
                                  focusNode: _fPhone,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _fLine1.requestFocus(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: _dec(
                                    label: 'เบอร์โทร (10 หลัก)',
                                    icon: Icons.call,
                                    controller: _phone,
                                  ),
                                  validator: (v) {
                                    final s = v?.trim() ?? '';
                                    if (s.isEmpty) return 'กรุณากรอกเบอร์โทร';
                                    if (s.length != 10) {
                                      return 'เบอร์โทรต้อง 10 หลัก';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ========== ส่วนที่อยู่จัดส่ง ==========
                  _sectionTitle('ที่อยู่จัดส่ง'),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _line1,
                            focusNode: _fLine1,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _fLine2.requestFocus(),
                            decoration: _dec(
                              label: 'ที่อยู่ (บรรทัด 1)',
                              hint: 'บ้านเลขที่/หมู่/ซอย/ถนน',
                              icon: Icons.home_outlined,
                              controller: _line1,
                            ),
                            validator: (v) => _required(v, 'ที่อยู่ (บรรทัด 1)'),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _line2,
                            focusNode: _fLine2,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => _fProvince.requestFocus(),
                            decoration: _dec(
                              label: 'ที่อยู่ (บรรทัด 2)',
                              hint: 'ตำบล/แขวง',
                              icon: Icons.location_on_outlined,
                              controller: _line2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _province,
                                  focusNode: _fProvince,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _fPostcode.requestFocus(),
                                  decoration: _dec(
                                    label: 'จังหวัด',
                                    icon: Icons.map_outlined,
                                    controller: _province,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 140,
                                child: TextFormField(
                                  controller: _postcode,
                                  focusNode: _fPostcode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                  decoration: _dec(
                                    label: 'รหัสไปรษณีย์',
                                    icon: Icons.markunread_mailbox_outlined,
                                    controller: _postcode,
                                  ),
                                  validator: (v) {
                                    final s = v?.trim() ?? '';
                                    if (s.isEmpty) return 'กรอกไปรษณีย์';
                                    if (s.length != 5) return 'ต้องเป็น 5 หลัก';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _setAsDefault,
                            onChanged: (v) => setState(() => _setAsDefault = v),
                            title: const Text('ตั้งเป็นที่อยู่เริ่มต้น'),
                            subtitle: const Text('ใช้สำหรับการสั่งซื้อครั้งต่อไปโดยอัตโนมัติ'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ========== พรีวิวที่อยู่ ==========
                  if (previewAddress.isNotEmpty) ...[
                    _sectionTitle('พรีวิวที่อยู่'),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.local_shipping_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_fullName.text.isEmpty ? '' : '${_fullName.text} • ${_phone.text}\n'}$previewAddress',
                                style: const TextStyle(height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ========== ปุ่มบันทึก ==========
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('บันทึกที่อยู่'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}