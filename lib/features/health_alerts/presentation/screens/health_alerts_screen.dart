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

  // Using relevant placeholder images for each category
  final List<Map<String, dynamic>> _alerts = [
    {
      'title': 'DOH, NNC launch Philippine Plan of Action for Nutrition 2023-2028',
      'description': 'The Department of Health and the National Nutrition Council officially launched the PPAN in Naga City.',
      'imageUrl': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/doh-nnc-launch-philippine-plan-of-action-for-nutrition-2023-2028/',
      'category': 'Lifestyle',
      'isNew': true,
    },
    {
      'title': 'Naga City bags Galing Pook Award for Health program',
      'description': 'Naga City has been recognized for its innovative "Naga City Health Emergency Response" initiative.',
      'imageUrl': 'https://images.unsplash.com/photo-1576091160550-2173dad99961?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/naga-city-bags-galing-pook-award-for-health-program/',
      'category': 'All',
      'isNew': false,
    },
    {
      'title': 'Naga Intensifies Vaccination Campaign against Measles and Polio',
      'description': 'City Health Office targets 100% coverage for children aged 0-59 months in recent Chikiting Ligtas campaign.',
      'imageUrl': 'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/naga-intensifies-vaccination-campaign-against-measles-and-polio/',
      'category': 'Vaccines',
      'isNew': false,
    },
    {
      'title': 'Mental Health Awareness Month observed in Naga City',
      'description': 'Naga City conducts various seminars and activities to promote mental wellness among its residents.',
      'imageUrl': 'https://images.unsplash.com/photo-1527137341206-193427974360?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/mental-health-awareness-month-observed-in-naga-city/',
      'category': 'Mental Health',
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
                  url: alert['url'],
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
