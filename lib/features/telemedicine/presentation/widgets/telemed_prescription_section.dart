import 'package:flutter/material.dart';
import '../../logic/prescription_state.dart';
import 'ataman_prescription_card.dart';

class TelemedPrescriptionSection extends StatelessWidget {
  final PrescriptionState state;
  final Function(dynamic) onPrescriptionTap;

  const TelemedPrescriptionSection({
    super.key,
    required this.state,
    required this.onPrescriptionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state is PrescriptionLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ));
    } else if (state is PrescriptionError) {
      return Center(child: Text((state as PrescriptionError).message));
    } else if (state is PrescriptionLoaded) {
      final prescriptions = (state as PrescriptionLoaded).prescriptions;
      if (prescriptions.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text("No active prescriptions found."),
        );
      } else {
        return Column(
          children: prescriptions.map((prescription) => AtamanPrescriptionCard(
            prescription: prescription,
            onTap: () => onPrescriptionTap(prescription),
          )).toList(),
        );
      }
    }
    return const SizedBox.shrink();
  }
}
