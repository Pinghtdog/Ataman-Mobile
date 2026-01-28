import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/constants.dart';
import 'data/models/notification_model.dart';
import 'logic/notification_cubit.dart';
import 'logic/notification_state.dart';
import 'presentation/widgets/notification_card.dart';
import 'presentation/widgets/notification_filter_chip.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }

          if (state is NotificationLoaded) {
            final notifications = state.filteredNotifications;
            final currentFilter = state.selectedFilter;
            final hasUnreadAlerts = state.notifications.any((n) => n.type == NotificationType.emergency && !n.isRead);

            return Column(
              children: [
                // Filter Chips Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    children: [
                      NotificationFilterChip(
                        label: "All",
                        isActive: currentFilter == 'All',
                        onTap: () => context.read<NotificationCubit>().setFilter('All'),
                      ),
                      const SizedBox(width: 12),
                      NotificationFilterChip(
                        label: "Emergency",
                        isActive: currentFilter == 'Emergency',
                        hasDot: hasUnreadAlerts,
                        onTap: () => context.read<NotificationCubit>().setFilter('Emergency'),
                      ),
                      const SizedBox(width: 12),
                      NotificationFilterChip(
                        label: "Bookings",
                        isActive: currentFilter == 'Bookings',
                        onTap: () => context.read<NotificationCubit>().setFilter('Bookings'),
                      ),
                    ],
                  ),
                ),

                // Notifications List
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return NotificationCard(
                              notification: notification,
                              onTap: () => context.read<NotificationCubit>().markAsRead(notification.id),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
