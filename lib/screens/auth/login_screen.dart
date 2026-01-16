import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../widgets/ataman_button.dart';
import '../../widgets/ataman_text_field.dart';
import '../../widgets/ataman_logo.dart';
import '../../widgets/auth/account_not_found_dialog.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    UiUtils.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      isPhoneLogin: false,
    );
  }

  // void _showAccountNotFoundDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AccountNotFoundDialog(
  //       onCreateAccount: () {
  //         Navigator.pushNamed(context, AppRoutes.register);
  //       },
  //       onCheckAgain: () {
  //         _emailController.clear();
  //         _passwordController.clear();
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          if (state.message.contains('Invalid login credentials')) {
            // _showAccountNotFoundDialog();
          } else {
            UiUtils.showError(context, state.message);
          }
        } else if (state is Authenticated) {
          UiUtils.showSuccess(context, "Welcome back!");
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.p20),
                  // const Center(child: AtamanLogoFull(height: 100)),
                  // const SizedBox(height: AppSizes.p48),

                  Text(
                    "Welcome Back",
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSizes.p8),
                  const Text(
                    "Sign in to access your records.",
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSizes.p48),

                  AtamanTextField(
                    label: "Email Address",
                    // hintText: "Enter your email",
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return AppStrings.fieldRequired;
                      if (!val.contains('@')) return AppStrings.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.p24),

                  AtamanTextField(
                    label: AppStrings.passwordLabel,
                    // hintText: "••••••••",
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) =>
                        val != null && val.isEmpty ? AppStrings.fieldRequired : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement Forgot Password
                      },
                      child: Text(
                        AppStrings.forgotPassword,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.p32),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return AtamanButton(
                        text: "Log In",
                        isLoading: state is AuthLoading,
                        onPressed: _handleLogin,
                      );
                    },
                  ),

                  const SizedBox(height: AppSizes.p32),

                  // Alternative Login Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.face_retouching_natural, color: AppColors.textSecondary),
                        label: const Text("Face ID", style: AppTextStyles.bodyMedium),
                      ),
                      const SizedBox(width: AppSizes.p16),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        icon: const Icon(Icons.person_add_outlined, color: AppColors.textSecondary),
                        label: const Text("Create Account", style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
