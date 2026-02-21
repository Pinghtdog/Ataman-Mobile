import 'package:flutter/material.dart';
import '../../logic/prescription_state.dart';
import '../../../../core/widgets/widgets.dart';
import 'ataman_prescription_card.dart';

class TelemedPrescriptionSection extends StatelessWidget {
  final PrescriptionState state;
  final Function(dynamic) onPrescriptionTap;

  const TelemedPrescriptionSection({
    super.key,
    required this.state,
    required this.onPrescriptionTap,
  });

  String _formatErrorMessage(String error) {
    if (error.contains('SocketException') || error.contains('connection abort')) {
      return "Connection error. Please check your internet and try again.";
    }
    if (error.contains('404')) return "Resource not found.";
    if (error.contains('500')) return "Server error. Please try again later.";
    return "Something went wrong while fetching prescriptions.";
  }

  @override
  Widget build(BuildContext context) {
    if (state is PrescriptionLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(),
      ));
    } else if (state is PrescriptionError) {
      final message = (state as PrescriptionError).message;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              "Unable to load prescriptions",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatErrorMessage(message),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    } else if (state is PrescriptionLoaded) {
      final prescriptions = (state as PrescriptionLoaded).prescriptions;
      if (prescriptions.isEmpty) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.grey.shade300, size: 40),
              const SizedBox(height: 12),
              Text(
                "No active prescriptions found.",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
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
