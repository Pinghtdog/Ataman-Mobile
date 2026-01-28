import 'package:ataman/core/constants/app_routes.dart';
import 'package:ataman/core/constants/app_strings.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/confidential_and_safe_card.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/consultation_mode_selector.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/services_grid.dart';
import 'package:flutter/material.dart';

class ReproductiveHealthScreen extends StatelessWidget {
  const ReproductiveHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reproductiveHealth),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ConfidentialAndSafeCard(),
            SizedBox(height: 24),
            Text(
              AppStrings.whatDoYouNeedHelpWith,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ServicesGrid(),
            SizedBox(height: 24),
            ConsultationModeSelector(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.generalConsult),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(AppStrings.connectWithSpecialist),
        ),
      ),
    );
  }
}
