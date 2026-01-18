import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/constants.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage/triage_cubit.dart';
import '../../logic/triage/triage_state.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Triage"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _textController.clear();
              context.read<TriageCubit>().reset();
              context.read<TriageCubit>().startTriage();
            },
          ),
        ],
      ),
      body: BlocListener<TriageCubit, TriageState>(
        listener: (context, state) {
          if (state is TriageSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TriageResultScreen(result: state.result),
              ),
            );
          } else if (state is TriageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
            );
          }
        },
        child: BlocBuilder<TriageCubit, TriageState>(
          builder: (context, state) {
            if (state is TriageLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TriageStepLoaded) {
              final step = state.step;
              return Padding(
                padding: const EdgeInsets.all(AppSizes.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: (state.history.length + 1) / 7,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: AppSizes.p32),
                    Text(
                      step.question,
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: AppSizes.p32),
                    if (step.inputType == TriageInputType.buttons)
                      Expanded(
                        child: ListView.separated(
                          itemCount: step.options.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p16),
                          itemBuilder: (context, index) {
                            final option = step.options[index];
                            return SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.read<TriageCubit>().selectOption(step.question, option);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSizes.p12),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
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
                        decoration: InputDecoration(
                          hintText: "Type your response here...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.p12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
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

            return const Center(child: Text("Initializing triage..."));
          },
        ),
      ),
    );
  }
}
