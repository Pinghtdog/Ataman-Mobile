import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../logic/auth_cubit.dart';
import '../widgets/mynagadialog.dart';

/// [AuthSelectionScreen] is the entry point for user authentication in the Ataman app.
///
/// This screen allows users to choose between two primary authentication methods:
/// 1. **MyNaga Authentication**: The recommended method for Naga City residents,
///    integrated via the [MyNagaAuthDialog].
/// 2. **Standard Login**: Allows users to sign in using their email or mobile number.
///
/// It listens to the [AuthCubit] state to handle navigation:
/// - If [Authenticated] or [AuthEmailVerified], the user is redirected to the home screen.
/// - If [AuthError], a snackbar is shown with the error message.
class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  /// Displays the [MyNagaAuthDialog] for identity-based authentication.
  ///
  /// The dialog is non-dismissible to ensure the user completes or explicitly
  /// cancels the authentication flow.
  void _showMyNagaAuth(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MyNagaAuthDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is AuthEmailVerified) {
          // Navigate to Home when successfully authenticated
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Logo section
              const Expanded(
                flex: 4,
                child: Center(
                  child: Hero(
                    tag: 'logo',
                    child: AtamanLogoFull(height: 300),
                  ),
                ),
              ),
              
              // Bottom content container with rounded corners
              Container(
                padding: const EdgeInsets.fromLTRB(AppSizes.p24, AppSizes.p48, AppSizes.p24, AppSizes.p32),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSizes.p48),
                    topRight: Radius.circular(AppSizes.p48),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Welcome to Ataman",
                      style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.p12),
                    const Text(
                      "Your gateway to Naga City's public health services.",
                      style: AppTextStyles.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.p48),
                    
                    // Primary CTA: MyNaga Authentication
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return AtamanButton(
                          text: "Continue with MyNaga",
                          isLoading: state is AuthLoading,
                          onPressed: () => _showMyNagaAuth(context),
                        );
                      },
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: AppSizes.p8),
                        child: Text(
                          "Recommended for Residents",
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.p24),
                    
                    // Separator
                    const Row(
                      children: [
                        Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
                          child: Text("OR", style: AppTextStyles.caption),
                        ),
                        Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.p24),
                    
                    // Secondary CTA: Email/Mobile Login
                    AtamanButton(
                      text: "Use Email/Mobile Number",
                      isOutlined: true,
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.login);
                      },
                    ),
                    
                    const SizedBox(height: AppSizes.p32),
                    
                    // Footer
                    Text(
                      "By logging in, you agree to our\nTerms & Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
