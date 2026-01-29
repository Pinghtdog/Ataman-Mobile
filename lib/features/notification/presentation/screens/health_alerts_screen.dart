import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/notification_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/notification_cubit.dart';
import '../../logic/notification_state.dart';

class HealthAlertsScreen extends StatelessWidget {
  const HealthAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanHeader(
            isSimple: true,
            height: 120,
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Health Alerts",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is NotificationLoaded) {
                  final alerts = state.notifications.where((n) => n.type == NotificationType.emergency).toList();
                  
                  if (alerts.isEmpty) {
                    return const Center(child: Text("No active health alerts. Stay safe!"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.danger.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              alert.body,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                "Reported: ${alert.createdAt.toString().split(' ')[0]}",
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
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
}
