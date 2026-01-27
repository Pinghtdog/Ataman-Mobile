import 'package:flutter/material.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../../core/widgets/widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AtamanSimpleHeader(
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
                  "Change Password",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your new password must be different from previously used passwords.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  _buildLabel("CURRENT PASSWORD"),
                  const SizedBox(height: 8),
                  AtamanTextField(
                    label: "",
                    hintText: "Enter current password",
                    isPassword: true,
                    controller: _currentPasswordController,
                  ),
                  const SizedBox(height: 24),
                  _buildLabel("NEW PASSWORD"),
                  const SizedBox(height: 8),
                  AtamanTextField(
                    label: "",
                    hintText: "Enter new password",
                    isPassword: true,
                    controller: _newPasswordController,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Must be at least 8 characters.",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel("CONFIRM PASSWORD"),
                  const SizedBox(height: 8),
                  AtamanTextField(
                    label: "",
                    hintText: "Re-enter new password",
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),
                  const SizedBox(height: 40),
                  AtamanButton(
                    text: "Update Password",
                    onPressed: () {
                      // Implementation for password update
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
