import 'package:ataman/core/constants/app_strings.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/add_photo_button.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/additional_details_input.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/next_available_gp_card.dart';
import 'package:ataman/features/reproductive_health/presentation/widgets/symptoms_chips.dart';
import 'package:ataman/features/vaccination/presentation/widgets/section_header.dart';
import 'package:flutter/material.dart';

class GeneralConsultScreen extends StatelessWidget {
  const GeneralConsultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.generalConsult),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            NextAvailableGPCard(),
            SizedBox(height: 24),
            SectionHeader(AppStrings.whatAreYouFeeling),
            SizedBox(height: 16),
            SymptomsChips(),
            SizedBox(height: 24),
            SectionHeader(AppStrings.additionalDetails),
            SizedBox(height: 16),
            AdditionalDetailsInput(),
            SizedBox(height: 16),
            AddPhotoButton(),
            SizedBox(height: 24),
            Text(AppStrings.dataPrivacyAgreement, style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
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
          child: const Text(AppStrings.joinQueue),
        ),
      ),
    );
  }
}
