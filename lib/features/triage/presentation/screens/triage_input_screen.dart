import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage_cubit.dart';
import '../../logic/triage_state.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';

import 'triage_result_screen.dart';

class TriageInputScreen extends StatefulWidget {
  const TriageInputScreen({super.key});

  @override
  State<TriageInputScreen> createState() => _TriageInputScreenState();
}

class _TriageInputScreenState extends State<TriageInputScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TriageCubit>().startTriage();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TriageCubit, TriageState>(
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              resizeToAvoidBottomInset: true,
              body: BlocListener<TriageCubit, TriageState>(
                listener: (context, state) {
                  if (state is TriageSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TriageResultScreen(result: state.result),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    AtamanSimpleHeader(
                      height: 120,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              onPressed: () {
                                context.read<TriageCubit>().reset();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const Center(
                            child: Text(
                              "Smart Triage",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                              onPressed: () {
                                _textController.clear();
                                context.read<TriageCubit>().reset();
                                context.read<TriageCubit>().startTriage();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildBody(state),
                    ),
                  ],
                ),
              ),
            ),
            AtamanLoader(isOpen: state is TriageLoading),
          ],
        );
      },
    );
  }

  Widget _buildBody(TriageState state) {
    if (state is TriageError) {
      final errorDetail = _getErrorDetail(state.message);
      return AtamanErrorState(
        title: errorDetail.title,
        message: errorDetail.description,
        icon: errorDetail.icon,
        buttonText: "Retry Analysis",
        onAction: () => context.read<TriageCubit>().retryLastStep(),
      );
    }

    if (state is TriageStepLoaded) {
      final step = state.step;
      
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (state.history.length + 1) / 7,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.question,
                    style: AppTextStyles.bodyLarge.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                  if (step.inputType == TriageInputType.buttons)
                    ...step.options.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.p16),
                          child: AtamanCard(
                            onTap: () {
                              context.read<TriageCubit>().selectOption(step.question, option);
                            },
                            padding: const EdgeInsets.all(AppSizes.p20),
                            child: Text(
                              option,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ))
                  else ...[
                    AtamanTextField(
                      label: "Your Response",
                      hintText: "Describe your symptoms or answer the question...",
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: AppSizes.p32),
                    AtamanButton(
                      text: "Next Step",
                      onPressed: () {
                        if (_textController.text.trim().isNotEmpty) {
                          context.read<TriageCubit>().selectOption(
                                step.question,
                                _textController.text.trim(),
                              );
                          _textController.clear();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return const Center(child: Text("Preparing triage..."));
  }

  _TriageErrorDetail _getErrorDetail(String rawError) {
    final String error = rawError.toLowerCase();
    
    if (error.contains("429") || error.contains("quota") || error.contains("overloaded")) {
      return const _TriageErrorDetail(
        title: "AI is Overloaded",
        description: "The ATAMAN AI engine is handling many requests. Please wait a minute before retrying.",
        icon: Icons.hourglass_top_rounded,
      );
    }
    
    if (error.contains("socket") || error.contains("network") || error.contains("connection")) {
      return const _TriageErrorDetail(
        title: "Connection Lost",
        description: "We can't reach the server. Please check your data connection or WiFi and try again.",
        icon: Icons.wifi_off_rounded,
      );
    }

    if (error.contains("gemini") || error.contains("ai engine") || error.contains("reasoning")) {
      return const _TriageErrorDetail(
        title: "AI Reasoning Error",
        description: "The AI assistant encountered a temporary glitch in its logic. Please retry the last step.",
        icon: Icons.psychology_outlined,
      );
    }

    return const _TriageErrorDetail(
      title: "Triage Interrupted",
      description: "We encountered an unexpected error. If you are in severe pain, please proceed directly to the nearest emergency room.",
      icon: Icons.report_gmailerrorred_rounded,
    );
  }
}

class _TriageErrorDetail {
  final String title;
  final String description;
  final IconData icon;

  const _TriageErrorDetail({
    required this.title,
    required this.description,
    required this.icon,
  });
}
