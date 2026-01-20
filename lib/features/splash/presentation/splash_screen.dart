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
  bool _timerFinished = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    
    setState(() {
      _timerFinished = true;
    });
    
    _checkAndNavigate(context.read<AuthCubit>().state);
  }

  void _checkAndNavigate(AuthState state) {
    if (_isNavigated || !mounted || !_timerFinished) return;

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
        if (_timerFinished) {
          _checkAndNavigate(state);
        }
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
