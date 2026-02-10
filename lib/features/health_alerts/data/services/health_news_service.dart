import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/health_news_model.dart';

class HealthNewsService {
  static final String _apiKey = dotenv.get('NEWS_API_KEY', fallback: '');
  static const String _baseUrl = 'https://newsapi.org/v2';

  Future<List<HealthArticle>> fetchHealthNews(String category) async {
    if (_apiKey.isEmpty) {
      print("Warning: News API Key is missing from .env");
      return [];
    }

    String endpoint;
    
    // Geographical keywords for Naga City and Bicol
    const String regionFilter = '("Naga City" OR "Bicol" OR "Camarines Sur")';

    if (category == 'All') {
      // General Health news in the region
      // Using /everything because /top-headlines doesn't support local keywords as well
      endpoint = '$_baseUrl/everything?q=$regionFilter AND (health OR medical OR hospital)&sortBy=publishedAt&language=en&apiKey=$_apiKey';
    } else {
      // Category specific news in the region (e.g., "Vaccines" in "Naga City")
      endpoint = '$_baseUrl/everything?q=$regionFilter AND $category&sortBy=publishedAt&language=en&apiKey=$_apiKey';
    }

    try {
      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['articles'];

        return articles
            .map((json) => HealthArticle.fromJson(json))
            .where((article) => 
                article.title != '[Removed]' && 
                article.url.isNotEmpty &&
                // Extra client-side check to ensure some relevance if keywords were broad
                (article.title.toLowerCase().contains('naga') || 
                 article.title.toLowerCase().contains('bicol') || 
                 article.description.toLowerCase().contains('naga') || 
                 article.description.toLowerCase().contains('bicol') ||
                 article.description.toLowerCase().contains('camarines')))
            .toList();
      } else {
        // If we get an error (like too many requests), fall back to PH-wide health news
        if (category == 'All') {
          final fallbackUrl = '$_baseUrl/top-headlines?country=ph&category=health&apiKey=$_apiKey';
          final fallbackResponse = await http.get(Uri.parse(fallbackUrl));
          if (fallbackResponse.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(fallbackResponse.body);
            final List<dynamic> articles = data['articles'];
            return articles.map((json) => HealthArticle.fromJson(json)).toList();
          }
        }
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print("Error fetching news: $e");
      return [];
    }
  }
}
