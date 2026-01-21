import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

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
            onPressed: () {
              // TODO: Implement mark all as read
            },
            child: Text(
              'Mark all as read',
              style: AppTextStyles.button.copyWith(color: AppColors.primary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.p4),
              children: [
                _notificationItem(
                  title: 'Emergency Request Update',
                  subtitle: 'Responder is on the way to your location.',
                  time: '2 hours ago',
                  isUnread: true,
                  icon: Icons.emergency_share,
                  iconBg: AppColors.danger.withOpacity(0.1),
                  iconColor: AppColors.danger,
                ),
                _notificationItem(
                  title: 'Appointment Reminder',
                  subtitle: 'Your booking at Naga Health Center is tomorrow at 9:00 AM.',
                  time: '1 day ago',
                  isUnread: false,
                  icon: Icons.calendar_today_rounded,
                  iconBg: AppColors.primary.withOpacity(0.1),
                  iconColor: AppColors.primary,
                ),
                _notificationItem(
                  title: 'Telemedicine Session',
                  subtitle: 'Dr. Santos has started the consultation room.',
                  time: '2 days ago',
                  isUnread: false,
                  icon: Icons.video_camera_front_rounded,
                  iconBg: AppColors.info.withOpacity(0.1),
                  iconColor: AppColors.info,
                ),
              ],
            ),
          ),
        ],
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

  Widget _notificationItem({
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p4),
      padding: const EdgeInsets.all(AppSizes.p4),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              if (isUnread)
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
                  title,
                  style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
