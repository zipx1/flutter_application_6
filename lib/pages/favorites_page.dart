import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../repos/favorites_repo.dart';
import '../repos/book_repo.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  void _toast(BuildContext context, String msg,
      {Color? color, IconData? icon, int seconds = 2}) {
    final bar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(msg)),
        ],
      ),
      duration: Duration(seconds: seconds),
      backgroundColor: color ?? Colors.black87,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(bar);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = authSnap.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ที่กดใจไว้')),
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('ไปหน้าเข้าสู่ระบบ'),
              ),
            ),
          );
        }

        final uid = user.uid;
        final favRepo = FavoritesRepo(uid);
        final bookRepo = BookRepo();

        return Scaffold(
          appBar: AppBar(title: const Text('ที่กดใจไว้')),
          body: StreamBuilder<Set<String>>(
            stream: favRepo.idsStream(),
            builder: (_, favSnap) {
              if (favSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final favIds = favSnap.data ?? <String>{};

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: bookRepo.booksStream(),
                builder: (_, bookSnap) {
                  if (bookSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allBooks = bookSnap.data ?? const <Map<String, dynamic>>[];
                  final books = allBooks
                      .where((b) => favIds.contains((b['id'] ?? '') as String))
                      .toList();

                  if (books.isEmpty) {
                    return const Center(child: Text('ยังไม่ได้กดใจเล่มใด'));
                  }

                  return ListView.separated(
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final b = books[i];
                      final id = (b['id'] ?? '') as String;
                      final title = (b['title'] ?? '') as String;
                      final price = ((b['price'] as num?) ?? 0).toDouble();
                      final coverUrl = (b['coverUrl'] ?? '').toString();

                      return ListTile(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/bookDetail',
                          arguments: id,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: coverUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: coverUrl,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(width: 50, height: 70, color: Colors.grey[200]),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                )
                              : const Icon(Icons.menu_book_outlined, size: 32),
                        ),
                        title: Text(
                          title.isEmpty ? 'ไม่มีชื่อ' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('฿${price.toStringAsFixed(0)}'),
                        trailing: IconButton(
                          tooltip: 'เอาออกจากที่กดใจ',
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            await favRepo.toggle(id, true);
                            _toast(context, 'เอาออกจากที่กดใจแล้ว',
                                color: Colors.redAccent,
                                icon: Icons.favorite_border);
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
