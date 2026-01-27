import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color bgColor;
    Color? accentColor;
    bool isUrgent = false;

    switch (notification.type) {
      case NotificationType.emergency:
        icon = Icons.emergency_share;
        iconColor = const Color(0xFFD32F2F);
        bgColor = const Color(0xFFFFCDD2);
        accentColor = const Color(0xFFFFEBEE);
        isUrgent = !notification.isRead;
        break;
      case NotificationType.booking:
        icon = Icons.calendar_today_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.primaryLight;
        accentColor = const Color(0xFFE0F2F1);
        break;
      case NotificationType.telemedicine:
        icon = Icons.video_camera_front_rounded;
        iconColor = AppColors.info;
        bgColor = AppColors.info.withOpacity(0.1);
        accentColor = AppColors.info.withOpacity(0.05);
        break;
      default:
        icon = Icons.notifications_none_rounded;
        iconColor = const Color(0xFF999999);
        bgColor = const Color(0xFFF5F5F5);
        accentColor = null;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accentColor != null)
                Container(width: 8, color: accentColor)
              else
                const SizedBox(width: 8),

              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: bgColor,
                        child: Icon(icon, color: iconColor, size: 18),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w900,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16, right: 16, left: 8),
                child: Text(
                  _formatTimestamp(notification.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                    color: isUrgent ? const Color(0xFF00695C) : const Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'NOW';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      if (difference.inDays == 1) return 'Yesterday';
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
