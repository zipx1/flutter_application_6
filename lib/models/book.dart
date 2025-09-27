class Book {
  final String id, title, author, coverUrl, category;
  final double price, rating;
  const Book({
    required this.id, required this.title, required this.author,
    required this.price, required this.coverUrl, required this.category, required this.rating,
  });
}
