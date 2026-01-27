import 'package:ataman/core/constants/app_strings.dart';
import 'package:dotted_border/dotted_border.dart';
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
          children: [
            _buildStockReservedCard(context),
            const SizedBox(height: 24),
            _buildSectionHeader(AppStrings.vaccine),
            _buildVaccineDropdown(),
            const SizedBox(height: 24),
            _buildSectionHeader(AppStrings.patient),
            _buildPatientSelection(),
            const SizedBox(height: 24),
            _buildSectionHeader(AppStrings.schedule),
            _buildScheduleSelector(),
            const SizedBox(height: 24),
            _buildSectionHeader(AppStrings.healthScreening),
            _buildHealthScreeningCard(),
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

  Widget _buildStockReservedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, style: BorderStyle.solid, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle, color: Colors.green, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(AppStrings.stockReservedForBooking, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(AppStrings.concepcionPequenaBHC, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVaccineDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        value: AppStrings.influenzaFluVaccine,
        items: [AppStrings.influenzaFluVaccine, AppStrings.pneumococcal23, AppStrings.antiRabies]
            .map((label) => DropdownMenuItem(
                  child: Text(label),
                  value: label,
                ))
            .toList(),
        onChanged: (value) {},
      ),
    );
  }

  Widget _buildPatientSelection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          _buildPatientCard(AppStrings.myself, isSelected: true),
          const SizedBox(width: 12),
          _buildPatientCard(AppStrings.miguelSon),
          const SizedBox(width: 12),
          _buildAddPatientCard(),
        ],
      ),
    );
  }

  Widget _buildPatientCard(String name, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.teal : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: isSelected ? Colors.teal : Colors.grey[300]),
          const SizedBox(height: 8),
          Text(name),
        ],
      ),
    );
  }

  Widget _buildAddPatientCard() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      color: Colors.grey[400]!,
      strokeWidth: 1,
      dashPattern: const [4, 4],
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, color: Colors.grey),
      ),
    );
  }

  Widget _buildScheduleSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildScheduleDetail(AppStrings.date, "Tomorrow, Oct 25"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildScheduleDetail(AppStrings.time, "8:00 AM"),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHealthScreeningCard() {
    return Card(
      margin: const EdgeInsets.only(top: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.doYouHaveFever),
            Row(
              children: [
                _buildChoiceChip(AppStrings.yes, false),
                const SizedBox(width: 8),
                _buildChoiceChip(AppStrings.no, true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
      backgroundColor: isSelected ? Colors.teal : Colors.grey[200],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      shape: const StadiumBorder(),
    );
  }
}
