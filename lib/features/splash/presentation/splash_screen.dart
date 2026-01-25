import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../auth/logic/auth_cubit.dart';

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
    // Check the current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate(context.read<AuthCubit>().state);
    });
  }

  void _checkAndNavigate(AuthState state) {
    if (_isNavigated || !mounted || state is AuthInitial) return;

    if (state is Authenticated) {
      _navigate(AppRoutes.home);
    } else if (state is Unauthenticated || state is AuthError) {
      // Unauthenticated or Error: move to selection screen
      _navigate(AppRoutes.authSelection);
    }
  }

  void _navigate(String routeName) {
    if (_isNavigated) return;
    _isNavigated = true;
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        _checkAndNavigate(state);
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Hero(
                tag: 'logo',
                child: AtamanLogoFull(height: 300),
              ),
              const SizedBox(height: AppSizes.p32),
              Text(
                AppStrings.appName,
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              Text(
                AppStrings.tagLine,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: AppSizes.p48),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
