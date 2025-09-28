import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart'; // isDarkMode / toggleTheme

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leadingW = constraints.maxWidth < 600 ? 180.0 : 260.0;

        return AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          centerTitle: true,
          leadingWidth: leadingW,

          // ชื่อร้านกลางเสมอ
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Comic Store',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          // ซ้าย: ผู้ใช้ + โหมดมืด
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 6),
              Flexible(child: _UserButton()),
              SizedBox(width: 4),
              _ThemeToggleButton(),
            ],
          ),

          // ขวา: ที่ชอบ + ตะกร้า
          actions: [
            _iconBox(
              icon: Icons.favorite_border,
              onPressed: () => _pushNamedRoot(context, '/favorites'),
            ),
            _iconBox(
              icon: Icons.shopping_cart_outlined,
              onPressed: () => _pushNamedRoot(context, '/cart'),
            ),
            const SizedBox(width: 6),
          ],
        );
      },
    );
  }

  static Widget _iconBox({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  /// ใช้ rootNavigator เสมอ เพื่อให้เรียกจากเมนู/บอททอมชีตได้ชัวร์
  static Future<T?> _pushNamedRoot<T>(BuildContext context, String route) {
    return Navigator.of(context, rootNavigator: true).pushNamed<T>(route);
  }
}

// -------------------- ปุ่มผู้ใช้ --------------------
class _UserButton extends StatelessWidget {
  const _UserButton();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        if (user == null) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed('/login'),
            child: const Text('ล็อกอิน', style: TextStyle(fontSize: 13)),
          );
        }

        final display = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : (user.email ?? 'gg-${user.uid}');
        return _GreetingPill(
          text: 'สวัสดี ${display.split('@').first}',
          onTap: () => _showProfileMenu(context, user),
        );
      },
    );
  }

  Future<void> _showProfileMenu(BuildContext context, User user) async {
    // คำนวณตำแหน่งเมนูให้ค่อนข้างเสถียร
    final overlayBox = Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    final selfBox = context.findRenderObject() as RenderBox?;
    final topLeft = selfBox?.localToGlobal(Offset.zero) ?? const Offset(0, kToolbarHeight);

    final pos = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + (selfBox?.size.height ?? 40),
      (overlayBox?.size.width ?? MediaQuery.sizeOf(context).width) - topLeft.dx,
      0,
    );

    await showMenu(
      context: context,
      position: pos,
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    gradient: LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white30,
                        child: Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName?.isNotEmpty == true ? user.displayName! : 'บัญชีผู้ใช้',
                              style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email ?? 'gg-${user.uid}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true)
                                .pushNamedAndRemoveUntil('/home', (r) => false);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('ออกจากระบบ', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                // เมนูย่อย
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('ข้อมูลของฉัน'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context, rootNavigator: true).pushNamed('/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('ที่อยู่จัดส่ง'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true, // ← ให้ขึ้นกับ root navigator
                      showDragHandle: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (sheetCtx) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.add_location_alt_outlined),
                              title: const Text('เพิ่มที่อยู่ใหม่'),
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                Navigator.of(context, rootNavigator: true).pushNamed('/add_address');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.location_on),
                              title: const Text('เลือก/แก้ไขที่อยู่เดิม'),
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                Navigator.of(context, rootNavigator: true).pushNamed('/select_address');
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------- pill ทักทาย --------------------
class _GreetingPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GreetingPill({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// -------------------- ปุ่มโหมดกลางคืน --------------------
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          color: Colors.white,
          size: 22,
        ),
        tooltip: isDarkMode ? 'ปิดโหมดกลางคืน' : 'เปิดโหมดกลางคืน',
        onPressed: toggleTheme,
      ),
    );
  }
}
