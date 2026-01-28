import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../widgets/category_selector.dart';
import '../widgets/health_alert_card.dart';
import '../widgets/health_alerts_header.dart';

class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen({super.key});

  @override
  State<HealthAlertsScreen> createState() => _HealthAlertsScreenState();
}

class _HealthAlertsScreenState extends State<HealthAlertsScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Vaccines', 'Mental Health', 'Lifestyle'];

  final List<Map<String, dynamic>> _alerts = [
    {
      'title': 'Dengue Alert: Prevention Tips',
      'description': 'Cases are rising in the metro. Learn how to protect your home and family with 5 simple steps...',
      'imageUrl': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&w=800&q=80',
      'category': 'Lifestyle',
      'isNew': false,
    },
    {
      'title': 'Flu Season Prep',
      'description': 'Schedule your annual flu shot today at any partner clinic to stay protected.',
      'imageUrl': 'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&w=800&q=80',
      'category': 'Vaccines',
      'isNew': true,
    },
    {
      'title': 'Mental Wellness Tip',
      'description': 'How 10 minutes of daily meditation can help lower stress and improve focus.',
      'imageUrl': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=800&q=80',
      'category': 'Mental Health',
      'isNew': false,
    },
    {
      'title': 'New Vaccine Guidelines',
      'description': 'Latest DOH updated protocols for pediatric vaccinations and booster shots.',
      'imageUrl': 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&w=800&q=80',
      'category': 'Vaccines',
      'isNew': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _selectedCategory == 'All'
        ? _alerts
        : _alerts.where((alert) => alert['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const HealthAlertsHeader(),
          CategorySelector(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              itemCount: filteredAlerts.length,
              itemBuilder: (context, index) {
                final alert = filteredAlerts[index];
                return HealthAlertCard(
                  title: alert['title'],
                  description: alert['description'],
                  imageUrl: alert['imageUrl'],
                  isNew: alert['isNew'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
