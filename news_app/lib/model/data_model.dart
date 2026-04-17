class NewsArticle {
  final String title;
  final String description;
  final String imageUrl;
  final String content;
  final String url;

  NewsArticle({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.content,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
    );
  }
}