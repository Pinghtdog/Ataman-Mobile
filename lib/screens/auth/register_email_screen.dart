import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../widgets/ataman_button.dart';
import '../../widgets/ataman_text_field.dart';
import '../../widgets/auth/check_email_dialog.dart';
import '../../widgets/auth/email_confirmed_dialog.dart';

class RegisterEmailScreen extends StatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  State<RegisterEmailScreen> createState() => _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends State<RegisterEmailScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  late Map<String, dynamic> fullProfileData;
  bool _isVerificationHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      fullProfileData = args;
    }
  }

  void _onCompleteRegistration() {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    if (email.isNotEmpty && pass.isNotEmpty) {
      context.read<AuthCubit>().register(
            email: email,
            password: pass,
            fullName: fullProfileData['fullName'],
            birthDate: fullProfileData['birthDate'],
            barangay: fullProfileData['barangay'],
            philhealthId: fullProfileData['philhealthId'],
          );
    }
  }

  void _showCheckEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckEmailDialog(
        email: _emailController.text.trim(),
        onContinue: () {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        },
      ),
    );
  }

  void _showEmailConfirmedDialog() {
    if (_isVerificationHandled) return;
    _isVerificationHandled = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailConfirmedDialog(
        onContinue: () async {
          await context.read<AuthCubit>().logout();//logout then they will log in hahahaa
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Secure Account"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            _showEmailConfirmedDialog(); //looged in after clicking emial link
          }
          if (state is AuthError) {
            if (state.message.contains("check your email")) {
              _showCheckEmailDialog();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Final Step",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text("Set up your login credentials."),
              const SizedBox(height: 32),
              
              AtamanTextField(
                label: "Email Address",
                hintText: "example@email.com",
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              
              AtamanTextField(
                label: "Password",
                hintText: "••••••••",
                controller: _passController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 16),

              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthError && !state.message.contains("check your email")) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              const Spacer(),
              
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return AtamanButton(
                    text: "Create Account",
                    isLoading: state is AuthLoading,
                    onPressed: _onCompleteRegistration,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
