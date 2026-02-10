class HealthArticle {
  final String title;
  final String description;
  final String url;
  final String? urlToImage;
  final String publishedAt;
  final String sourceName;

  HealthArticle({
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    required this.sourceName,
  });

  factory HealthArticle.fromJson(Map<String, dynamic> json) {
    return HealthArticle(
      title: json['title'] ?? 'No Title',
      // Handling cases where description is null or removed
      description: json['description'] ?? 'Click to read more about this health update.',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'] ?? '',
      sourceName: json['source']['name'] ?? 'News',
    );
  }
}