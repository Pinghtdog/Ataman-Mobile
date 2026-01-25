import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/utils/validator_utils.dart';
import '../../logic/auth_cubit.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/check_email_dialog.dart';
import '../widgets/email_confirmed_dialog.dart';

class RegisterEmailScreen extends StatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  State<RegisterEmailScreen> createState() => _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends State<RegisterEmailScreen> {
  final _formKey = GlobalKey<FormState>();
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

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _onCompleteRegistration() {
    UiUtils.hideKeyboard(context);
    
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
            firstName: fullProfileData['firstName'],
            lastName: fullProfileData['lastName'],
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
          await context.read<AuthCubit>().logout();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthEmailVerified) {
            _showEmailConfirmedDialog();
          }
          if (state is AuthError) {
            if (state.message.contains("check your email")) {
              _showCheckEmailDialog();
            } else {
            }
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.p8),
                  Text(
                    "Final Step",
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  const Text(
                    "Set up your login credentials.",
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.p32),
                  
                  const AtamanLabel(text: "EMAIL ADDRESS"),
                  AtamanTextField(
                    label: "",
                    hintText: "example@email.com",
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: ValidatorUtils.validateEmail,
                  ),
                  const SizedBox(height: AppSizes.p24),
                  
                  const AtamanLabel(text: "PASSWORD"),
                  AtamanTextField(
                    label: "",
                    hintText: "••••••••",
                    controller: _passController,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: ValidatorUtils.validatePassword,
                  ),
    
                  const SizedBox(height: AppSizes.p16),
    
                  // Inline Error display
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthError && !state.message.contains("check your email")) {
                        return Padding(
                          padding: const EdgeInsets.only(left: AppSizes.p4),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                              const SizedBox(width: AppSizes.p8),
                              Expanded(
                                child: Text(
                                  state.message,
                                  style: AppTextStyles.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  const SizedBox(height: AppSizes.p48),
                  
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return AtamanButton(
                        text: "Create Account",
                        isLoading: state is AuthLoading,
                        onPressed: _onCompleteRegistration,
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.p32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
