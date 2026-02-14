import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/utils/validator_utils.dart';
import '../../logic/auth_cubit.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/philhealth_service.dart';
import '../../../../injector.dart';
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
  final _philhealthController = TextEditingController();
  late Map<String, dynamic> fullProfileData;
  bool _isVerificationHandled = false;
  bool _isPhilhealthValid = false;

  @override
  void initState() {
    super.initState();
    _philhealthController.addListener(_validatePhilhealth);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      fullProfileData = args;
      if (fullProfileData['philhealthId'] != null) {
        _philhealthController.text = fullProfileData['philhealthId'];
      }
    }
  }

  void _validatePhilhealth() {
    final isValid = getIt<PhilHealthService>().validatePIN(_philhealthController.text);
    if (isValid != _isPhilhealthValid) {
      setState(() => _isPhilhealthValid = isValid);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _philhealthController.dispose();
    super.dispose();
  }

  void _onCompleteRegistration() {
    print('ATAMAN_DEBUG: "Create Account" button tapped');
    UiUtils.hideKeyboard(context);
    
    final bool isValid = _formKey.currentState?.validate() ?? false;
    print('ATAMAN_DEBUG: Form validation result: $isValid');

    if (isValid) {
      print('ATAMAN_DEBUG: Calling AuthCubit.register for ${_emailController.text}');
      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            password: _passController.text.trim(),
            firstName: fullProfileData['firstName'],
            lastName: fullProfileData['lastName'],
            birthDate: fullProfileData['birthDate'],
            barangay: fullProfileData['barangay'],
            philhealthId: _philhealthController.text.trim(),
          );
    } else {
      print('ATAMAN_DEBUG: Registration blocked by local validation errors');
    }
  }

  void _showCheckEmailDialog() {
    print('ATAMAN_DEBUG: Showing CheckEmailDialog for ${_emailController.text}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CheckEmailDialog(
        email: _emailController.text.trim(),
        onContinue: () {
          print('ATAMAN_DEBUG: CheckEmailDialog closed, navigating to login');
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
            print('ATAMAN_DEBUG: AuthState is AuthEmailVerified');
            _showEmailConfirmedDialog();
          }
          if (state is AuthError) {
            print('ATAMAN_DEBUG: AuthState is AuthError: ${state.message}');
            if (state.message.contains("check your email")) {
              _showCheckEmailDialog();
            }
          }
          if (state is Authenticated) {
            print('ATAMAN_DEBUG: AuthState is Authenticated');
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
                    "Verify your PhilHealth and set up login.",
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.p32),

                  const AtamanLabel(text: "PHILHEALTH ID (OPTIONAL)"),
                  AtamanTextField(
                    label: "",
                    hintText: "XX-XXXXXXXXX-X",
                    controller: _philhealthController,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    suffixIcon: _isPhilhealthValid 
                      ? const Icon(Icons.check_circle, color: Colors.green) 
                      : null,
                    helperText: _isPhilhealthValid ? "PIN Validated & Verified" : "Enter 12-digit PIN for instant verification",
                  ),
                  const SizedBox(height: AppSizes.p24),
                  
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
