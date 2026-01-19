import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../widgets/ataman_button.dart';
import '../../widgets/ataman_text_field.dart';
import '../../widgets/ataman_loader.dart';
import '../../widgets/ataman_label.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../utils/ui_utils.dart';
import '../../utils/validator_utils.dart';
import '../../widgets/auth/account_not_found_dialog.dart';

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
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
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
                  if (state is Authenticated) {
                    final bool isComplete = state.profile?.isProfileComplete ?? false;
                    
                    if (isComplete) {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.register);
                    }
                  }
                  if (state is AuthError) {
                    final isAccountNotFound = state.message.toLowerCase().contains("incorrect") ||
                                             state.message.toLowerCase().contains("not found");
                    
                    if (isAccountNotFound) {
                      final identity = _identityController.text.trim();
                      final isEmail = !RegExp(r'^\+?[0-9]+$').hasMatch(identity);

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AccountNotFoundDialog(
                          isEmail: isEmail,
                          onCreateAccount: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          onRetry: () {
                            _passwordController.clear();
                          },
                        ),
                      );
                    } else {
                      UiUtils.showError(context, state.message);
                    }
                  }
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSizes.p24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sign In",
                                style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(height: AppSizes.p8),
                              const Text(
                                "Access your records with email or mobile number.",
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: AppSizes.p32),

                              const AtamanLabel(text: "EMAIL OR MOBILE NUMBER"),
                              AtamanTextField(
                                label: "",
                                controller: _identityController,
                                prefixIcon: Icons.person_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) => (val == null || val.isEmpty) ? "This field is required" : null,
                              ),
                              const SizedBox(height: AppSizes.p24),

                              const AtamanLabel(text: "PASSWORD"),
                              AtamanTextField(
                                label: "",
                                controller: _passwordController,
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                validator: ValidatorUtils.validatePassword,
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

                              AtamanButton(
                                text: "Log In",
                                onPressed: _handleLogin,
                              ),

                              const SizedBox(height: AppSizes.p32),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Don't have an account?", style: AppTextStyles.bodyMedium),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                                    child: Text(
                                      "Create Account", 
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AtamanLoader(isOpen: state is AuthLoading),
          ],
        );
      },
    );
  }
}
