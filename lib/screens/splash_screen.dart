import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/constants.dart';
import '../widgets/ataman_logo.dart';
import '../logic/auth/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    
    _checkAndNavigate(context.read<AuthCubit>().state);
  }

  void _checkAndNavigate(AuthState state) {
    if (_isNavigated || !mounted) return;

    if (state is Authenticated) {
      _isNavigated = true;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (state is Unauthenticated || state is AuthError) {
      _isNavigated = true;
      Navigator.pushReplacementNamed(context, AppRoutes.authSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AtamanLogoFull(height: 180),
              const SizedBox(height: AppSizes.p32),
              Text(
                AppStrings.appName,
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              const Text(
                AppStrings.tagLine,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSizes.p48),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
