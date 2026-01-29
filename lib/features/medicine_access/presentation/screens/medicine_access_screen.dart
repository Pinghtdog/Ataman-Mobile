import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/medicine_card.dart';
import '../widgets/medicine_search_header.dart';

class MedicineAccessScreen extends StatefulWidget {
  const MedicineAccessScreen({super.key});

  @override
  State<MedicineAccessScreen> createState() => _MedicineAccessScreenState();
}

class _MedicineAccessScreenState extends State<MedicineAccessScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      // Fetching from facility_medicines which links the medicines catalog to specific facilities
      final response = await _supabase
          .from('facility_medicines')
          .select('''
            *,
            medicines (
              name,
              description,
              icon_name,
              category
            ),
            facilities (
              name
            )
          ''')
          .gt('stock_count', 0);

      if (mounted) {
        setState(() {
          _medications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _medications.isEmpty
                ? const AtamanEmptyState(
                    title: "No Medicines Found",
                    message: "There are currently no medicines listed as available in the network.",
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: AppSizes.p16,
                      mainAxisSpacing: AppSizes.p16,
                    ),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final item = _medications[index];
                      final med = item['medicines'] as Map<String, dynamic>;
                      final facility = item['facilities'] as Map<String, dynamic>;
                      
                      return MedicineCard(
                        name: med['name'] ?? 'Unknown',
                        description: "Available at: ${facility['name']}",
                        inStock: (item['stock_count'] ?? 0) > 0,
                        icon: Icons.medication_rounded,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.hospitalAvailability,
                            arguments: med['name'],
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
