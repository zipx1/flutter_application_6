import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart'; // สำหรับ toggleTheme()

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // กำหนด leadingWidth อิงขนาดหน้าจอ
        final leadingW = constraints.maxWidth < 600 ? 180.0 : 260.0;

        return AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          centerTitle: true,
          leadingWidth: leadingW,

          // ✅ ชื่อร้านตรงกลางแน่นอน
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

          // ✅ ฝั่งซ้าย (ล็อกอิน + ปุ่มโหมดกลางคืน)
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 6),
              Flexible(child: _UserButton()),
              SizedBox(width: 4),
              _ThemeToggleButton(),
            ],
          ),

          // ✅ ฝั่งขวา (หัวใจ + ตะกร้า)
          actions: [
            _iconBox(
              icon: Icons.favorite_border,
              onPressed: () => Navigator.pushNamed(context, '/favorites'),
            ),
            _iconBox(
              icon: Icons.shopping_cart_outlined,
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
            const SizedBox(width: 6),
          ],
        );
      },
    );
  }

  static Widget _iconBox({required IconData icon, required VoidCallback onPressed}) {
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
}

// ✅ ปุ่มผู้ใช้
class _UserButton extends StatelessWidget {
  const _UserButton();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;

        // ยังไม่ล็อกอิน
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
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text(
              'ล็อกอิน',
              style: TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
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
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final box = context.findRenderObject() as RenderBox?;
    final topLeft = box?.localToGlobal(Offset.zero) ?? Offset.zero;

    final rect = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + (box?.size.height ?? 0),
      overlay.size.width - topLeft.dx,
      0,
    );

    await showMenu(
      context: context,
      position: rect,
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 280,
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
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName!
                                  : 'บัญชีผู้ใช้',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
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
                            Navigator.pushReplacementNamed(context, '/login');
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
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('เพิ่มที่อยู่'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/address');
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

// ✅ pill ทักทายผู้ใช้
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

// ✅ ปุ่มโหมดกลางคืน
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
