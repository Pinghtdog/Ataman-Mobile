import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import 'data/models/notification_model.dart';
import 'logic/notification_cubit.dart';
import 'logic/notification_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
            child: Text(
              'Mark all as read',
              style: AppTextStyles.button.copyWith(color: AppColors.primary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }

          if (state is NotificationLoaded) {
            final notifications = state.filteredNotifications;

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildTabs(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.p4),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return InkWell(
                        onTap: () => context.read<NotificationCubit>().markAsRead(notification.id),
                        child: _notificationItem(notification),
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

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: AppSizes.p4, left: AppSizes.p4),
      child: Row(
        children: [
          _filterChip('All', true),
          _filterChip('Emergency', false),
          _filterChip('Bookings', false),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.textPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isSelected ? AppColors.surface : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _notificationItem(NotificationModel notification) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.emergency:
        icon = Icons.emergency_share;
        iconBg = AppColors.danger.withOpacity(0.1);
        iconColor = AppColors.danger;
        break;
      case NotificationType.booking:
        icon = Icons.calendar_today_rounded;
        iconBg = AppColors.primary.withOpacity(0.1);
        iconColor = AppColors.primary;
        break;
      case NotificationType.telemedicine:
        icon = Icons.video_camera_front_rounded;
        iconBg = AppColors.info.withOpacity(0.1);
        iconColor = AppColors.info;
        break;
      case NotificationType.general:
      default:
        icon = Icons.notifications_none_rounded;
        iconBg = AppColors.textSecondary.withOpacity(0.1);
        iconColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p4),
      padding: const EdgeInsets.all(AppSizes.p4),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.surface.withOpacity(0.7) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.p4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: iconBg,
                radius: 20,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (!notification.isRead)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(notification.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}
