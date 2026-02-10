import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/models/doctor_model.dart';
import '../../logic/telemedicine_cubit.dart';
import '../widgets/telemed_booking_sheet.dart';

class AvailableDoctorsScreen extends StatefulWidget {
  const AvailableDoctorsScreen({super.key});

  @override
  State<AvailableDoctorsScreen> createState() => _AvailableDoctorsScreenState();
}

class _AvailableDoctorsScreenState extends State<AvailableDoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _showBookingSheet(BuildContext context, DoctorModel doctor) {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => TelemedBookingSheet(
          doctor: doctor,
          userId: authState.user.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanHeader(
            isSimple: true,
            height: 180,
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Available Doctors",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.white70),
                      border: InputBorder.none,
                      hintText: "Search doctor or specialty...",
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TelemedicineCubit, TelemedicineState>(
              builder: (context, state) {
                if (state is TelemedicineLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TelemedicineLoaded) {
                  final filteredDoctors = state.doctors.where((d) {
                    final name = d.fullName.toLowerCase();
                    final specialty = (d.specialty ?? "").toLowerCase();
                    return name.contains(_searchQuery) || specialty.contains(_searchQuery);
                  }).toList();

                  if (filteredDoctors.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("No doctors found", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = filteredDoctors[index];
                      return _buildDoctorListItem(context, doctor);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorListItem(BuildContext context, DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 30),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: doctor.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    doctor.specialty ?? "General Practice",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text("4.8 (120 reviews)", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showBookingSheet(context, doctor),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(70, 36),
              ),
              child: const Text("Book"),
            ),
          ],
        ),
      ),
    );
  }
}
