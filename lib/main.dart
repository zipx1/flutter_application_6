import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// theme controller (สำหรับสลับโหมดกลางคืน)
import 'utils/app_theme.dart';

// pages
import 'pages/home_page.dart';
import 'pages/cart_page.dart';
import 'pages/payment_page.dart';
import 'pages/favorites_page.dart';
import 'pages/book_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/address_page.dart';
import 'pages/profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final app = Firebase.app();
  final opts = app.options;
  // Log ไว้ดูค่า config (ไม่กระทบการทำงาน)
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
    // ✅ ฟังค่า themeMode จากตัวควบคุม (toggle จากปุ่มใน AppBar)
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Comic Store',

          // ✅ ธีมปกติ + ธีมมืด + เลือกโหมดตามตัวควบคุม
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
            scaffoldBackgroundColor: Colors.black, // พื้นหลังดำสนิท
          ),

          home: const HomePage(),

          // ✅ routes ปกติ
          routes: {
            '/home': (_) => const HomePage(),
            '/cart': (_) => const CartPage(),
            '/payment': (_) => const PaymentPage(),
            '/favorites': (_) => const FavoritesPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/address': (_) => const AddressPage(),
            '/profile': (_) => const ProfilePage(),
          },

          // ✅ /bookDetail รับ arguments เป็น bookId
          onGenerateRoute: (settings) {
            if (settings.name == '/bookDetail') {
              final id = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => BookDetailPage(bookId: id),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
