// lib/pages/home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/book_grid.dart';
import '../widgets/custom_top_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _search = ''; // ✅ ค่าค้นหา

  @override
  Widget build(BuildContext context) {
    // 🔹 Stream หนังสือทั้งหมด (กรองด้วย search)
    final booksQuery = FirebaseFirestore.instance.collection('books');
    final booksStream = (_search.trim().isEmpty)
        ? booksQuery.orderBy('title').snapshots()
        : booksQuery
            .where('title', isGreaterThanOrEqualTo: _search)
            .where('title', isLessThanOrEqualTo: '$_search\uf8ff')
            .snapshots();

    // 🔹 Stream หนังสือขายดี
    final bestSellersStream = FirebaseFirestore.instance
        .collection('books')
        .where('isBestSeller', isEqualTo: true)
        .limit(5)
        .snapshots();

    final titleColor = Theme.of(context).textTheme.titleLarge?.color;

    return Scaffold(
      appBar: const CustomTopBar(),
      body: Column(
        children: [
          // 🔍 กล่องค้นหา
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาหนังสือ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
          ),
          const SizedBox(height: 8),

          // ✅ เนื้อหาทั้งหมด (scroll ได้)
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: booksStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                      child: Text(
                    _search.isEmpty ? 'ยังไม่มีหนังสือ' : 'ไม่พบหนังสือตรงกับ "${_search}"',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                  ));
                }

                final docs = snap.data!.docs;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    const targetCardWidth = 180.0;
                    final crossAxisCount =
                        (constraints.maxWidth / targetCardWidth)
                            .floor()
                            .clamp(2, 6);

                    return CustomScrollView(
                      slivers: [
                        // ====== สินค้าขายดี ======
                        if (_search.isEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📚 สินค้าขายดี',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // แสดงแนวนอน
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 270,
                              child: StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: bestSellersStream,
                                builder: (context, bestSnap) {
                                  if (bestSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (!bestSnap.hasData ||
                                      bestSnap.data!.docs.isEmpty) {
                                    return Center(
                                        child: Text('ยังไม่มีสินค้าขายดี',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color)));
                                  }

                                  final bestDocs = bestSnap.data!.docs;
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    itemCount: bestDocs.length,
                                    itemBuilder: (context, i) {
                                      final d = bestDocs[i].data();
                                      final id = bestDocs[i].id;
                                      return _BestSellerCard(
                                        id: id,
                                        title: (d['title'] ?? '').toString(),
                                        price: (d['price'] is num)
                                            ? (d['price'] as num).toDouble()
                                            : 0.0,
                                        coverUrl:
                                            (d['coverUrl'] ?? '').toString(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          // เส้นคั่น
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Divider(
                                  color: Theme.of(context).dividerColor,
                                  height: 1),
                            ),
                          ),
                        ],

                        // ====== หัวข้อหนังสือทั้งหมด ======
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  _search.isEmpty
                                      ? 'หนังสือทั้งหมด'
                                      : 'ผลการค้นหา',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ====== กริดหนังสือทั้งหมด ======
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.60,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final doc = docs[index];
                                final d = doc.data();
                                return BookGrid(
                                  bookId: doc.id,
                                  title: (d['title'] ?? '').toString(),
                                  price: d['price'],
                                  coverUrl: d['coverUrl'],
                                );
                              },
                              childCount: docs.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดเล่มขายดีแนวนอน
class _BestSellerCard extends StatelessWidget {
  final String id;
  final String title;
  final double price;
  final String coverUrl;

  const _BestSellerCard({
    required this.id,
    required this.title,
    required this.price,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bodyTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/bookDetail',
              arguments: id), // ✅ แก้ path ให้ถูก
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: bodyTextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 37, 185, 0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
