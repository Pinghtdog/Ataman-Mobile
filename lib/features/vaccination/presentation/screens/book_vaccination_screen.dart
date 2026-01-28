import 'package:ataman/core/constants/app_strings.dart';
import 'package:ataman/features/vaccination/presentation/widgets/health_screening_card.dart';
import 'package:ataman/features/vaccination/presentation/widgets/patient_selection.dart';
import 'package:ataman/features/vaccination/presentation/widgets/schedule_selector.dart';
import 'package:ataman/features/vaccination/presentation/widgets/section_header.dart';
import 'package:ataman/features/vaccination/presentation/widgets/stock_reserved_card.dart';
import 'package:ataman/features/vaccination/presentation/widgets/vaccine_dropdown.dart';
import 'package:flutter/material.dart';

class BookVaccinationScreen extends StatelessWidget {
  const BookVaccinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.bookVaccination),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            StockReservedCard(),
            SizedBox(height: 24),
            SectionHeader(AppStrings.vaccine),
            VaccineDropdown(),
            SizedBox(height: 24),
            SectionHeader(AppStrings.patient),
            PatientSelection(),
            SizedBox(height: 24),
            SectionHeader(AppStrings.schedule),
            ScheduleSelector(),
            SizedBox(height: 24),
            SectionHeader(AppStrings.healthScreening),
            HealthScreeningCard(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(AppStrings.confirmVaccinationSlot),
        ),
      ),
    );
  }
}
