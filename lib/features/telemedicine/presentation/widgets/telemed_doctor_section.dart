import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../logic/telemedicine_cubit.dart';
import '../../data/models/doctor_model.dart';
import '../../../../core/constants/constants.dart';
import 'telemed_booking_sheet.dart';

class TelemedDoctorSection extends StatelessWidget {
  final TelemedicineState state;

  const TelemedDoctorSection({
    super.key,
    required this.state,
  });

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
    if (state is TelemedicineLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    List<DoctorModel>? doctors;
    if (state is TelemedicineLoaded) {
      doctors = (state as TelemedicineLoaded).doctors;
    }

    if (doctors == null || doctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("No doctors available for scheduling at this time."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Available Doctors", style: AppTextStyles.h3),
            TextButton(onPressed: () {}, child: const Text("View All")),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors![index];
              return _buildDoctorCard(context, doctor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(BuildContext context, DoctorModel doctor) {
    return GestureDetector(
      onTap: () => _showBookingSheet(context, doctor),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 30),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: doctor.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              doctor.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              doctor.specialty ?? "General Practice",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
