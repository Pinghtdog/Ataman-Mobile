import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../logic/auth_cubit.dart';
import '../widgets/patient_enrollment_form.dart';

class PatientEnrollmentScreen extends StatelessWidget {
  final UserModel user;
  const PatientEnrollmentScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Patient Enrollment"),
            Text(
              "Required for DOH iClinicSys",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: PatientEnrollmentForm(
        user: user,
        onSave: (updatedUser) {
          context.read<AuthCubit>().updateProfile(updatedUser);
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
