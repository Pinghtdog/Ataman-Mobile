import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/logic/locale_cubit.dart';
import 'settings/change_password_screen.dart';
import 'settings/notifications_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/profile_cubit.dart';
import '../../logic/profile_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
                Text(
                  l10n.settings,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionTitle(l10n.account),
                _buildCard([
                  _buildSettingTile(
                    title: l10n.personalInformation,
                    onTap: () {
                      final profileState = context.read<ProfileCubit>().state;
                      if (profileState is ProfileSuccess) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: profileState.user),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSettingTile(
                    title: l10n.changePassword,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.changePassword);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle(l10n.preferences),
                _buildCard([
                  _buildSettingTile(
                    title: l10n.notifications,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: (val) => setState(() => _notificationsEnabled = val),
                          activeColor: AppColors.primary,
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.notificationSettings);
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSettingTile(
                    title: l10n.language,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocBuilder<LocaleCubit, Locale>(
                          builder: (context, locale) {
                            String languageName = l10n.english;
                            if (locale.languageCode == 'tl') languageName = l10n.filipino;
                            if (locale.languageCode == 'bik') languageName = l10n.bikolNaga;
                            
                            return Text(
                              languageName,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.language);
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle(l10n.legal),
                _buildCard([
                  _buildSettingTile(
                    title: l10n.privacyPolicy,
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSettingTile(
                    title: l10n.termsOfService,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    "Version 1.0.2 • Naga City Government",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
