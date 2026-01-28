import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../widgets/medicine_card.dart';
import '../widgets/medicine_search_header.dart';

class MedicineAccessScreen extends StatefulWidget {
  const MedicineAccessScreen({super.key});

  @override
  State<MedicineAccessScreen> createState() => _MedicineAccessScreenState();
}

class _MedicineAccessScreenState extends State<MedicineAccessScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _medicines = [
    {
      'name': 'Amoxicillin',
      'description': '500mg Capsule',
      'inStock': true,
      'icon': Icons.medication_rounded,
    },
    {
      'name': 'Paracetamol',
      'description': '500mg Tablet',
      'inStock': true,
      'icon': Icons.grid_view_rounded,
    },
    {
      'name': 'Insulin Glargine',
      'description': '100 units/mL',
      'inStock': false,
      'icon': Icons.colorize_rounded,
    },
    {
      'name': 'Salbutamol',
      'description': '100mcg Inhaler',
      'inStock': true,
      'icon': Icons.air_rounded,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          MedicineSearchHeader(controller: _searchController),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSizes.p16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: AppSizes.p16,
                mainAxisSpacing: AppSizes.p16,
              ),
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final medicine = _medicines[index];
                return MedicineCard(
                  name: medicine['name'],
                  description: medicine['description'],
                  inStock: medicine['inStock'],
                  icon: medicine['icon'],
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.hospitalAvailability,
                      arguments: medicine['name'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
