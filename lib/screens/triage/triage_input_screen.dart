import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage/triage_cubit.dart';
import '../../logic/triage/triage_state.dart';
import '../../widgets/ataman_simple_header.dart';
import '../../widgets/ataman_error_state.dart';
import '../../widgets/ataman_loader.dart';
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
      return AtamanErrorState(
        title: "Triage AI Error",
        message: _getFriendlyErrorMessage(state.message),
        icon: Icons.auto_awesome_motion_rounded,
        buttonText: "Retry Analysis",
        onAction: () => context.read<TriageCubit>().retryLastStep(),
      );
    }

    if (state is TriageStepLoaded) {
      final step = state.step;
      return Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (state.history.length + 1) / 7,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSizes.p32),
            Text(
              step.question,
              style: AppTextStyles.h2.copyWith(height: 1.3),
            ),
            const SizedBox(height: AppSizes.p32),
            if (step.inputType == TriageInputType.buttons)
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: step.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p16),
                  itemBuilder: (context, index) {
                    final option = step.options[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            context.read<TriageCubit>().selectOption(step.question, option);
                          },
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          child: Padding(
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
                        ),
                      ),
                    );
                  },
                ),
              )
            else ...[
              TextField(
                controller: _textController,
                maxLines: 4,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Type your response here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.p12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.p12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.p12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_textController.text.trim().isNotEmpty) {
                      context.read<TriageCubit>().selectOption(
                            step.question,
                            _textController.text.trim(),
                          );
                      _textController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.p12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p24),
            ],
          ],
        ),
      );
    }

    return const Center(child: Text("Preparing triage..."));
  }

  String _getFriendlyErrorMessage(String rawError) {
    if (rawError.contains("429")) {
      return "The AI assistant is taking a short break due to high demand. Please wait a minute and try again.";
    }
    if (rawError.contains("Gemini")) {
      return "The AI assistant is having trouble communicating. Please check your internet or try again later.";
    }
    return "We encountered an issue during analysis. Please retry or visit a facility if urgent.";
  }
}
