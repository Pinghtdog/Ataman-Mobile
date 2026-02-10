import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../widgets/category_selector.dart';
import '../widgets/health_alert_card.dart';
import '../widgets/health_alerts_header.dart';
import '../../data/models/health_news_model.dart';
import '../../data/services/health_news_service.dart';


class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen({super.key});

  @override
  State<HealthAlertsScreen> createState() => _HealthAlertsScreenState();
}

class _HealthAlertsScreenState extends State<HealthAlertsScreen> {
  final HealthNewsService _newsService = HealthNewsService();
  String _selectedCategory = 'All';
  List<HealthArticle> _articles = [];
  bool _isLoading = true;
  final List<String> _categories = ['All', 'Vaccines', 'Mental Health', 'Nutrition'];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() => _isLoading = true);

    // Fetch data based on selected category
    final articles = await _newsService.fetchHealthNews(_selectedCategory);

    if (mounted) {
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchNews(); // Refetch when category changes
  }

  // Function to open the URL
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const HealthAlertsHeader(),

          CategorySelector(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategoryChanged,
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _articles.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _fetchNews,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                itemCount: _articles.length,
                itemBuilder: (context, index) {
                  final article = _articles[index];

                  // Check if the article is "New" (published within last 24 hours)
                  final pubDate = DateTime.tryParse(article.publishedAt);
                  final isNew = pubDate != null &&
                      DateTime.now().difference(pubDate).inHours < 24;

                  return GestureDetector(
                    onTap: () => _launchURL(article.url),
                    child: HealthAlertCard(
                      title: article.title,
                      description: article.description,
                      // Use a placeholder if image is null
                      imageUrl: article.urlToImage ?? 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=800&q=80',
                      url: article.url,
                      isNew: isNew,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No news found for $_selectedCategory",
            style: TextStyle(color: Colors.grey[600]),
          ),
          TextButton(
            onPressed: _fetchNews,
            child: const Text("Try Again"),
          )
        ],
      ),
    );
  }
}