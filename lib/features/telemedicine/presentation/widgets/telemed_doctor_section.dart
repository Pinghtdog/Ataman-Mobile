import 'package:flutter/material.dart';
import '../../logic/telemedicine_cubit.dart';
import 'ataman_konsulta_card.dart';

class TelemedDoctorSection extends StatelessWidget {
  final TelemedicineState state;
  final Function(String) onJoinCall;

  const TelemedDoctorSection({
    super.key,
    required this.state,
    required this.onJoinCall,
  });

  @override
  Widget build(BuildContext context) {
    if (state is TelemedicineLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (state is TelemedicineDoctorsLoaded) {
      final doctors = (state as TelemedicineDoctorsLoaded).doctors;
      if (doctors.isEmpty) {
        return const AtamanKonsultaCard(
          title: "No Doctors Online",
          subtitle: "Please check back later.",
          nextAvailable: "None",
        );
      }

      final doctor = doctors.first;
      return AtamanKonsultaCard(
        title: "PhilHealth Konsulta",
        subtitle: doctor.fullName,
        nextAvailable: doctor.isOnline ? "Next Available ( ${doctor.currentWaitMinutes}m wait)" : "Offline",
        onJoinTap: doctor.isOnline ? () => onJoinCall(doctor.id) : null,
      );
    }

    return const SizedBox.shrink();
  }
}
