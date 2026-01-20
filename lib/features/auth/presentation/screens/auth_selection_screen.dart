import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Logo
            const Expanded(
              flex: 4,
              child: Center(
                child: Hero(
                  tag: 'logo',
                  child: AtamanLogoFull(height: 300),
                ),
              ),
            ),
            
            // Content
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
                  
                  AtamanButton(
                    text: "Continue with MyNaga",
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
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
                  
                  AtamanButton(
                    text: "Use Email/Mobile Number",
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                  ),
                  
                  const SizedBox(height: AppSizes.p32),
                  
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
    );
  }
}
