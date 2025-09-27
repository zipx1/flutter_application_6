import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repos/favorites_repo.dart';
import '../repos/book_repo.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

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
            appBar: AppBar(title: const Text('Favorites')),
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('ไปหน้าเข้าสู่ระบบ'),
              ),  
            ),
          );
        }

        final uid = user.uid;

        return Scaffold(
          appBar: AppBar(title: const Text('ที่กดใจไว้')),
          body: StreamBuilder<Set<String>>(
            stream: FavoritesRepo(uid).idsStream(),
            builder: (_, favSnap) {
              if (favSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final favIds = favSnap.data ?? <String>{};

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: BookRepo().booksStream(), // ถ้าใช้ API, ให้แน่ใจว่าคืน List<Map>
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

                      return ListTile(
                        leading: const Icon(Icons.book_outlined),
                        title: Text(title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${price.toStringAsFixed(0)} ฿'),
                        trailing: IconButton(
                          tooltip: 'เอาออกจากถูกใจ',
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () =>
                              FavoritesRepo(uid).toggle(id, true),
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
