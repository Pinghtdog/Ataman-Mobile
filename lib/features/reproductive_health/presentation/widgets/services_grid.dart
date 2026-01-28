import 'package:ataman/core/constants/app_strings.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/service_card.dart';
import 'package:flutter/material.dart';

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: const [
        ServiceCard(icon: Icons.family_restroom, title: AppStrings.familyPlanning, subtitle: AppStrings.pillsImplantsIUD, color: Colors.pink),
        ServiceCard(icon: Icons.favorite, title: AppStrings.sexualHealth, subtitle: AppStrings.stiHivScreening, color: Colors.purple),
        ServiceCard(icon: Icons.pregnant_woman, title: AppStrings.maternalCare, subtitle: AppStrings.prenatalPostnatal, color: Colors.blue),
        ServiceCard(icon: Icons.psychology, title: AppStrings.counseling, subtitle: AppStrings.guidanceAndSupport, color: Colors.orange),
      ],
    );
  }
}
