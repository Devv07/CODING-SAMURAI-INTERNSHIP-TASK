class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? tag;
  final double rating;
  final int reviews;
  final String imageEmoji;
  final String colorHex;
  final String description;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.tag,
    required this.rating,
    required this.reviews,
    required this.imageEmoji,
    required this.colorHex,
    required this.description,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id:          json['id']?.toString() ?? '',
      name:        json['name'] as String,
      price:       (json['price'] as num).toDouble(),
      category:    json['category'] as String,
      tag:         json['tag'] as String?,
      rating:      (json['rating'] as num).toDouble(),
      reviews:     (json['reviews'] as num).toInt(),
      imageEmoji:  json['imageEmoji'] as String,
      colorHex:    json['colorHex'] as String,
      description: json['description'] as String,
      isActive:    json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'name':        name,
    'price':       price,
    'category':    category,
    'tag':         tag,
    'rating':      rating,
    'reviews':     reviews,
    'imageEmoji':  imageEmoji,
    'colorHex':    colorHex,
    'description': description,
    'isActive':    isActive,
  };

  Product copyWith({
    String? name, double? price, String? category, String? tag,
    double? rating, int? reviews, String? imageEmoji,
    String? colorHex, String? description, bool? isActive,
  }) {
    return Product(
      id:          id,
      name:        name        ?? this.name,
      price:       price       ?? this.price,
      category:    category    ?? this.category,
      tag:         tag         ?? this.tag,
      rating:      rating      ?? this.rating,
      reviews:     reviews     ?? this.reviews,
      imageEmoji:  imageEmoji  ?? this.imageEmoji,
      colorHex:    colorHex    ?? this.colorHex,
      description: description ?? this.description,
      isActive:    isActive    ?? this.isActive,
    );
  }
}
