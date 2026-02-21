import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage_cubit.dart';
import '../../logic/triage_state.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import 'triage_result_screen.dart';

/// [TriageInputScreen] is the interactive interface for the Ataman Smart Triage system.
///
/// This screen facilitates a dynamic, AI-driven conversation where users describe
/// their symptoms and answer follow-up questions to determine the urgency and
/// type of medical care required.
///
/// **Functionality:**
/// 1. **Dynamic Questioning**: Loads steps sequentially from the [TriageCubit].
/// 2. **Hybrid Input**: Supports predefined AI options (buttons) for quick selection
///    and manual text input for detailed descriptions.
/// 3. **Progress Tracking**: Displays a visual indicator of the triage progress.
/// 4. **Resiliency**: Includes specialized error handling for AI service quotas,
///    network interruptions, and server timeouts.
/// 5. **Navigation**: Automatically transitions to the [TriageResultScreen] once
///     the AI determines a final assessment.
class TriageInputScreen extends StatefulWidget {
  const TriageInputScreen({super.key});

  @override
  State<TriageInputScreen> createState() => _TriageInputScreenState();
}

class _TriageInputScreenState extends State<TriageInputScreen> {
  final TextEditingController _textController = TextEditingController();
  
  /// Flag used to switch from button-based selection to manual text input 
  /// when the user selects a "None of the above" type option.
  bool _forceManualInput = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<TriageCubit>();
    if (cubit.state is TriageInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cubit.startTriage();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<TriageCubit, TriageState>(
        listener: (context, state) {
          if (state is TriageSuccess) {
            final cubit = context.read<TriageCubit>();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: TriageResultScreen(result: state.result),
                ),
              ),
            );
          }
          if (state is TriageStepLoaded) {
            setState(() {
              _textController.clear();
              _forceManualInput = false;
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  AtamanHeader(
                    isSimple: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () {
                              context.read<TriageCubit>().reset();
                              Navigator.pop(context);
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "Smart Triage",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                            onPressed: () {
                              _textController.clear();
                              context.read<TriageCubit>().reset();
                              context.read<TriageCubit>().startTriage();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildBody(state),
                  ),
                ],
              ),
              AtamanLoader(isOpen: state is TriageLoading),
            ],
          );
        },
      ),
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
      final bool showButtons = step.inputType == TriageInputType.buttons &&
          !_forceManualInput &&
          step.options.isNotEmpty;

      return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ((state.history.length + 1) / 5).clamp(0.0, 1.0),
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

                    if (showButtons) ...[
                      ...step.options.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.p16),
                        child: AtamanCard(
                          onTap: () {
                            if (option.toLowerCase().contains("none of the above")) {
                              setState(() => _forceManualInput = true);
                            } else {
                              context.read<TriageCubit>().selectOption(step.question, option);
                            }
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
                      )),
                    ] else ...[
                      AtamanTextField(
                        label: "Your Response",
                        hintText: "Describe your symptoms or answer the question...",
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                        autoFocus: true,
                      ),
                      const SizedBox(height: AppSizes.p24),
                      AtamanButton(
                        text: step.placeholder ?? "Submit Response",
                        onPressed: () {
                          if (_textController.text.trim().isNotEmpty) {
                            context.read<TriageCubit>().selectOption(
                              step.question,
                              _textController.text.trim(),
                            );
                          }
                        },
                      ),
                      if (step.inputType == TriageInputType.buttons)
                        TextButton(
                          onPressed: () => setState(() => _forceManualInput = false),
                          child: const Center(child: Text("Back to options")),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text("Preparing triage..."));
  }

  _TriageErrorDetail _getErrorDetail(String rawError) {
    final String error = rawError.toLowerCase();
    if (error.contains("429") || error.contains("quota")) {
      return const _TriageErrorDetail(
        title: "AI is Overloaded",
        description: "The system is busy. Please wait a moment before retrying.",
        icon: Icons.hourglass_top_rounded,
      );
    }
    if (error.contains("socket") || error.contains("network") || error.contains("connection")) {
      return const _TriageErrorDetail(
        title: "Connection Lost",
        description: "We can't reach the server. Please check your internet connection.",
        icon: Icons.wifi_off_rounded,
      );
    }
    return const _TriageErrorDetail(
      title: "Triage Interrupted",
      description: "Unexpected error. If this is an emergency, go to the nearest hospital.",
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
