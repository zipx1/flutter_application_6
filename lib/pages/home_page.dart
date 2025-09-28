import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/book_grid.dart';
import '../widgets/custom_top_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Stream หนังสือทั้งหมด
    final booksStream = FirebaseFirestore.instance
        .collection('books')
        .orderBy('title')
        .snapshots();

    // 🔹 Stream หนังสือขายดี (เลือกเองโดยตั้ง isBestSeller: true)
    final bestSellersStream = FirebaseFirestore.instance
        .collection('books')
        .where('isBestSeller', isEqualTo: true)
        .limit(5)
        .snapshots();

    return Scaffold(
      // 💡 แก้ไข: ลบ backgroundColor ออกเพื่อให้ใช้สีพื้นหลังของธีม (ขาว/ดำ)
      appBar: const CustomTopBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: booksStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            // 💡 แก้ไข: ใช้สีข้อความหลักจากธีม
            return Center(child: Text('ยังไม่มีหนังสือ', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)));
          }

          final docs = snap.data!.docs;
          final titleColor = Theme.of(context).textTheme.titleLarge?.color; // 💡 ดึงสีหัวข้อ

          return LayoutBuilder(
            builder: (context, constraints) {
              const targetCardWidth = 180.0;
              final crossAxisCount =
                  (constraints.maxWidth / targetCardWidth).floor().clamp(2, 6);

              return CustomScrollView(
                slivers: [
                  // ====== ส่วนหัวข้อ "สินค้าขายดี" ======
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '📚 สินค้าขายดี',
                            style: TextStyle(
                              color: titleColor, // 💡 ใช้สีที่เปลี่ยนตามธีม
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ====== แสดงรายการขายดีแนวนอน ======
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 270, // ✅ เพิ่มความสูง แก้ overflow
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: bestSellersStream,
                        builder: (context, bestSnap) {
                          if (bestSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!bestSnap.hasData ||
                              bestSnap.data!.docs.isEmpty) {
                            // 💡 แก้ไข: ใช้สีข้อความหลักจากธีม
                            return Center(
                                child: Text('ยังไม่มีสินค้าขายดี',
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)));
                          }

                          final bestDocs = bestSnap.data!.docs;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
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
                                coverUrl: (d['coverUrl'] ?? '').toString(),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // ====== เส้นคั่น ======
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      // 💡 ใช้ Divider ที่เปลี่ยนสีตามธีม
                      child: Divider(color: Theme.of(context).dividerColor, height: 1), 
                    ),
                  ),

                  // ====== หัวข้อหนังสือทั้งหมด ======
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'หนังสือทั้งหมด',
                            style: TextStyle(
                              color: titleColor, // 💡 ใช้สีที่เปลี่ยนตามธีม
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
    // 💡 ดึงสีข้อความหลักจากธีม
    final bodyTextColor = Theme.of(context).textTheme.bodyLarge?.color; 

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/book', arguments: id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ รูปสัดส่วนเล็กลงนิด ลดโอกาสล้น
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 0.72, // เดิม 3/4 → ปรับให้อ้วนขึ้นนิดนึง
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

              // ✅ เนื้อหา
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 💡 แก้ไข: ใช้ bodyTextColor
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(fontWeight: FontWeight.w600, color: bodyTextColor), 
                    ),
                    const SizedBox(height: 4),
                    // 💡 แก้ไข: ราคายังคงใช้สีเขียวคงที่ (อ่านง่าย)
                    Text(
                      '฿${price.toStringAsFixed(0)}',
                      style: const TextStyle( 
                        color: Color.fromARGB(255, 37, 185, 0), // ราคามักจะใช้สีคงที่ เช่น สีเขียว
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