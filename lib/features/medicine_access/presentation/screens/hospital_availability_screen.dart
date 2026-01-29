import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/hospital_availability_card.dart';
import '../widgets/hospital_availability_header.dart';

class HospitalAvailabilityScreen extends StatefulWidget {
  final String medicineName;

  const HospitalAvailabilityScreen({
    super.key,
    required this.medicineName,
  });

  @override
  State<HospitalAvailabilityScreen> createState() => _HospitalAvailabilityScreenState();
}

class _HospitalAvailabilityScreenState extends State<HospitalAvailabilityScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      // Fetch availability from facility_medicines joined with facilities and medicines
      final response = await _supabase
          .from('facility_medicines')
          .select('''
            price,
            stock_count,
            facilities (
              name,
              address
            ),
            medicines!inner (
              name
            )
          ''')
          .eq('medicines.name', widget.medicineName)
          .gt('stock_count', 0);

      if (mounted) {
        setState(() {
          _availability = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading availability: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HospitalAvailabilityHeader(medicineName: widget.medicineName),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availability.isEmpty
                    ? const AtamanEmptyState(
                        title: "No Availability",
                        message: "This medicine is currently not available in any nearby facility.",
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        itemCount: _availability.length,
                        itemBuilder: (context, index) {
                          final item = _availability[index];
                          final facility = item['facilities'] as Map<String, dynamic>;
                          
                          return HospitalAvailabilityCard(
                            hospitalName: facility['name'] ?? 'Unknown Facility',
                            distance: facility['address'] ?? 'Location N/A',
                            inStock: (item['stock_count'] ?? 0) > 0,
                            price: (item['price'] as num).toDouble(),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
