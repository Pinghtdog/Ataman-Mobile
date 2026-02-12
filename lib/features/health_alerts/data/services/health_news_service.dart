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

    // Geographical keywords for Naga City and Bicol
    const String regionFilter = '("Naga City" OR "Bicol" OR "Philippines")';
    String q = '';

    if (category == 'All') {
      q = '$regionFilter AND (health OR medical OR "DOH")';
    } else {
      q = '$regionFilter AND $category';
    }

    final endpoint = '$_baseUrl/everything?q=$q&sortBy=publishedAt&language=en&apiKey=$_apiKey';

    try {
      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['articles'];

        final results = articles
            .map((json) => HealthArticle.fromJson(json))
            .where((article) => 
                article.title != '[Removed]' && 
                article.title.isNotEmpty &&
                article.url.isNotEmpty)
            .toList();

        // If no specific results found with "Naga/Bicol", fall back to general PH health news
        if (results.isEmpty) {
          return await _fetchPHFallback(category);
        }

        return results;
      } else {
        return await _fetchPHFallback(category);
      }
    } catch (e) {
      print("Error fetching news: $e");
      return await _fetchPHFallback(category);
    }
  }

  /// Fallback to top health headlines from the Philippines
  Future<List<HealthArticle>> _fetchPHFallback(String category) async {
    String url = '$_baseUrl/top-headlines?country=ph&category=health&apiKey=$_apiKey';
    
    // If a specific category like "Vaccines" was requested, use it as a query
    if (category != 'All') {
      url = '$_baseUrl/top-headlines?country=ph&q=$category&apiKey=$_apiKey';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articles = data['articles'];
        return articles
            .map((json) => HealthArticle.fromJson(json))
            .where((a) => a.title != '[Removed]')
            .toList();
      }
    } catch (e) {
      print("Fallback failed: $e");
    }
    return [];
  }
}
