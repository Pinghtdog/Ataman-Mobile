import 'package:flutter/material.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../../core/widgets/widgets.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _appointments = true;
  bool _healthAlerts = true;
  bool _messages = true;
  bool _tipsEvents = false;

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
                  "Notifications",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                _buildNotificationTile(
                  title: "Appointments",
                  subtitle: "Reminders for upcoming visits.",
                  value: _appointments,
                  onChanged: (val) => setState(() => _appointments = val),
                ),
                _buildNotificationTile(
                  title: "Health Alerts",
                  subtitle: "Epidemics and emergency news.",
                  value: _healthAlerts,
                  onChanged: (val) => setState(() => _healthAlerts = val),
                ),
                _buildNotificationTile(
                  title: "Messages",
                  subtitle: "Chats from doctors/triage.",
                  value: _messages,
                  onChanged: (val) => setState(() => _messages = val),
                ),
                _buildNotificationTile(
                  title: "Tips & Events",
                  subtitle: "Vaccine drives and health tips.",
                  value: _tipsEvents,
                  onChanged: (val) => setState(() => _tipsEvents = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            trailing: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
