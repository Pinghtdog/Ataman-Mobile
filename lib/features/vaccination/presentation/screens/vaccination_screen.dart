import 'package:flutter/material.dart';
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
  VaccineCategory _selectedCategory = VaccineCategory.all;

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
                FilterChips(
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
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
                    
                    var vaccines = snapshot.data ?? [];
                    
                    // Client-side filtering based on minAgeMonths
                    if (_selectedCategory == VaccineCategory.kids) {
                      vaccines = vaccines.where((v) => v.minAgeMonths < 216).toList(); // < 18 years
                    } else if (_selectedCategory == VaccineCategory.adults) {
                      vaccines = vaccines.where((v) => v.minAgeMonths >= 216).toList(); // >= 18 years
                    } else if (_selectedCategory == VaccineCategory.seniors) {
                      vaccines = vaccines.where((v) => v.minAgeMonths >= 720).toList(); // >= 60 years
                    }

                    if (vaccines.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text('No vaccines found for this category.'),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vaccines.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final vaccine = vaccines[index];
                        
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

                        return VaccineListItem(
                          abbr: vaccine.abbr ?? vaccine.name.substring(0, 3).toUpperCase(),
                          name: vaccine.name,
                          description: vaccine.description ?? 'Available at partnered facilities',
                          stockStatus: globalStatus,
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
