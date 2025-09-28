import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// theme controller
import 'utils/app_theme.dart';

// pages
import 'pages/home_page.dart';
import 'pages/cart_page.dart';
import 'pages/payment_page.dart';
import 'pages/favorites_page.dart';
import 'pages/book_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/add_address_page.dart';
import 'pages/select_address_page.dart';
import 'pages/profile_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final app = Firebase.app();
  final opts = app.options;
  // ignore: avoid_print
  print(
    'FIREBASE CONFIG -> projectId=${opts.projectId}, appId=${opts.appId}, authDomain=${opts.authDomain}',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Comic Store',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),

          // หน้าแรก
          home: const HomePage(),

          // ✅ routes ที่ “ไม่ต้องส่ง argument”
          routes: {
            '/home': (_) => const HomePage(),
            '/cart': (_) => const CartPage(),
            '/favorites': (_) => const FavoritesPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/add_address': (_) => const AddAddressPage(),
            '/select_address': (_) => const SelectAddressPage(),
            '/profile': (_) => const ProfilePage(),
            '/payment_success': (_) => const _PaymentSuccessPage(),
          },

          // ✅ routes ที่ “ต้องส่ง argument”
          onGenerateRoute: (settings) {
            // ---------- 📘 หน้าแสดงรายละเอียดหนังสือ ----------
            if (settings.name == '/bookDetail') {
              final id = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => BookDetailPage(bookId: id),
              );
            }

            // ---------- 💳 หน้า Payment ----------
            if (settings.name == '/payment') {
              final args = (settings.arguments as Map?) ?? const {};

              double toDouble(dynamic v) {
                if (v is num) return v.toDouble();
                final s = v?.toString() ?? '0';
                final cleaned = s.replaceAll(RegExp(r'[^0-9\.\-]'), '');
                return double.tryParse(cleaned) ?? 0.0;
              }

              final total =
                  toDouble(args['total'] ?? args['totalPrice'] ?? 0);

              // ✅ แปลง items เป็น List<Map<String,dynamic>> อย่างปลอดภัย
              final rawItems = args['items'];
              final List<Map<String, dynamic>> items = (rawItems is List)
                  ? rawItems
                      .whereType<Map>() // กรองเฉพาะที่เป็น Map
                      .map((m) => Map<String, dynamic>.from(m))
                      .toList()
                  : const <Map<String, dynamic>>[];

              return MaterialPageRoute(
                builder: (_) => PaymentPage(
                  totalPrice: total,
                  items: items,
                ),
              );
            }

            // ---------- ค่าเริ่มต้น ----------
            return null;
          },
        );
      },
    );
  }
}

/// ✅ หน้า success หลังชำระเงินเสร็จ
class _PaymentSuccessPage extends StatelessWidget {
  const _PaymentSuccessPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงินสำเร็จ')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'คำสั่งซื้อถูกสร้างเรียบร้อย ขอบคุณที่ชำระเงิน!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (_) => false,
              ),
              child: const Text('กลับหน้าแรก'),
            ),
          ],
        ),
      ),
    );
  }
}
