import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../widgets/ataman_button.dart';
import '../../widgets/ataman_text_field.dart';
import '../../widgets/ataman_logo.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../utils/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    UiUtils.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final identity = _identityController.text.trim();
    final password = _passwordController.text.trim();
    
    final isPhone = RegExp(r'^\+?[0-9]+$').hasMatch(identity);

    context.read<AuthCubit>().login(
      identity, 
      password,
      isPhoneLogin: isPhone,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          UiUtils.showError(context, state.message);
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
                  // const SizedBox(height: AppSizes.p32),s

                  Text(
                    "Welcome Back",
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSizes.p8),
                  const Text(
                    "Sign in with your email or mobile number.",
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSizes.p48),

                  AtamanTextField(
                    label: "Email or Mobile Number",
                    hintText: "Enter email or phone",
                    controller: _identityController,
                    prefixIcon: Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.isEmpty) return "This field is required";
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.p24),

                  AtamanTextField(
                    label: AppStrings.passwordLabel,
                    hintText: "••••••••",
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) =>
                        val != null && val.isEmpty ? "Please enter your password" : null,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: AppTextStyles.bodyMedium),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
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
