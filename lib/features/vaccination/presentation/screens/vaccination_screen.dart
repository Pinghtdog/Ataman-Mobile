import 'package:ataman/core/constants/app_routes.dart';
import 'package:ataman/core/constants/app_strings.dart';
import 'package:ataman/features/vaccination/presentation/widgets/filter_chips.dart';
import 'package:ataman/features/vaccination/presentation/widgets/immunization_card.dart';
import 'package:ataman/features/vaccination/presentation/widgets/vaccine_list_item.dart';
import 'package:flutter/material.dart';

class VaccinationScreen extends StatelessWidget {
  const VaccinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vaccinationServices),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ImmunizationCard(),
              const SizedBox(height: 24),
              const Text(
                AppStrings.availableVaccines,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const FilterChips(),
              const SizedBox(height: 16),
              _buildVaccineList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccineList(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.bookVaccination),
          child: const VaccineListItem(
            abbr: 'FLU',
            name: AppStrings.influenzaFluVaccine,
            description: AppStrings.prioritySeniorsIndigents,
            stockStatus: StockStatus.inStock,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.bookVaccination),
          child: const VaccineListItem(
            abbr: 'PNE',
            name: AppStrings.pneumococcal23,
            description: AppStrings.lifetimeProtection,
            stockStatus: StockStatus.inStock,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.bookVaccination),
          child: const VaccineListItem(
            abbr: 'RAB',
            name: AppStrings.antiRabies,
            description: AppStrings.animalBiteCenterOnly,
            stockStatus: StockStatus.limited,
          ),
        ),
        const SizedBox(height: 12),
        const VaccineListItem(
          abbr: 'TET',
          name: AppStrings.tetanusToxoid,
          description: AppStrings.checkAvailability,
          stockStatus: StockStatus.noStock,
        ),
      ],
    );
  }
}
