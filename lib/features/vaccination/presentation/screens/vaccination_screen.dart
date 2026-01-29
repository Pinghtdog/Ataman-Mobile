import 'package:flutter/material.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../injector.dart';
import '../../data/models/vaccine_model.dart';
import '../../data/repositories/vaccine_repository.dart';
import '../widgets/filter_chips.dart';
import '../widgets/immunization_card.dart';
import '../widgets/vaccine_list_item.dart';

class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({super.key});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  late Future<List<Vaccine>> _vaccinesFuture;

  @override
  void initState() {
    super.initState();
    _vaccinesFuture = getIt<VaccineRepository>().getAvailableVaccines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vaccinationServices),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _vaccinesFuture = getIt<VaccineRepository>().getAvailableVaccines();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                FutureBuilder<List<Vaccine>>(
                  future: _vaccinesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    final vaccines = snapshot.data ?? [];
                    if (vaccines.isEmpty) {
                      return const Center(child: Text('No vaccines available.'));
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vaccines.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final vaccine = vaccines[index];
                        
                        // Aggregating stock across multiple facilities (Hospitals/Pharmacies)
                        // This handles the challenge of fragmented inventories by normalizing them
                        // into a single global status for the user.
                        StockStatus globalStatus = StockStatus.noStock;
                        if (vaccine.inventory != null && vaccine.inventory!.isNotEmpty) {
                          final hasInStock = vaccine.inventory!.any((inv) => inv.status == 'IN_STOCK');
                          final hasLimited = vaccine.inventory!.any((inv) => inv.status == 'LIMITED');
                          
                          if (hasInStock) {
                            globalStatus = StockStatus.inStock;
                          } else if (hasLimited) {
                            globalStatus = StockStatus.limited;
                          }
                        }

                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context, 
                            AppRoutes.bookVaccination,
                            arguments: vaccine,
                          ),
                          child: VaccineListItem(
                            abbr: vaccine.abbr ?? vaccine.name.substring(0, 3).toUpperCase(),
                            name: vaccine.name,
                            description: vaccine.description ?? 'Available at partnered facilities',
                            stockStatus: globalStatus,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
