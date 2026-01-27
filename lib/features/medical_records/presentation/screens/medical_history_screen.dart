import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/medical_history_model.dart';
import '../widgets/medical_history_timeline_item.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Consultations", "Labs"];

  // Mock data for display - this would normally come from a repository/cubit
  final List<MedicalHistoryItem> _allHistory = [
    MedicalHistoryItem(
      id: '1',
      title: "General Consultation",
      subtitle: "Tele-Ataman • Dr. Santos",
      date: DateTime(2025, 10, 24),
      type: MedicalRecordType.consultation,
      tag: "Diagnosis: Flu",
    ),
    MedicalHistoryItem(
      id: '2',
      title: "Immunization",
      subtitle: "Concepcion BHC",
      date: DateTime(2025, 9, 10),
      type: MedicalRecordType.immunization,
      extraInfo: "Flu Shot",
    ),
    MedicalHistoryItem(
      id: '3',
      title: "Emergency Room",
      subtitle: "NCGH • Triage Level 3",
      date: DateTime(2025, 8, 5),
      type: MedicalRecordType.emergency,
      tag: "Minor Injury",
    ),
    MedicalHistoryItem(
      id: '4',
      title: "Blood Test (CBC)",
      subtitle: "Hi-Precision Diagnostics",
      date: DateTime(2025, 1, 5),
      type: MedicalRecordType.lab,
      hasPdf: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<MedicalHistoryItem> filteredHistory = _allHistory.where((item) {
      if (_selectedFilter == "All") return true;
      if (_selectedFilter == "Consultations") return item.type == MedicalRecordType.consultation;
      if (_selectedFilter == "Labs") return item.type == MedicalRecordType.lab;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanSimpleHeader(
            height: 120,
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Medical History",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF333333) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                final item = filteredHistory[index];
                return MedicalHistoryTimelineItem(
                  item: item,
                  isLast: index == filteredHistory.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
