import 'dart:async';

import 'package:flutter/material.dart';
import 'package:v60pal/AddJournalEntryScreen.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/widgets/app_ui.dart';

class TimerScreen extends StatefulWidget {
  final Recipe recipe;

  const TimerScreen({super.key, required this.recipe});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  Timer? timer;
  int elapsedSeconds = 0;
  int currentStepIndex = 0;
  bool isRunning = false;
  late AnimationController stepController;

  List<int> get brewStepTimes => widget.recipe.pourSteps;

  List<int> get brewAmounts => widget.recipe.pourAmounts;

  @override
  void initState() {
    super.initState();
    stepController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          advanceStep();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTimer();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    stepController.dispose();
    super.dispose();
  }

  void startTimer() {
    if (isRunning) return;
    setState(() {
      isRunning = true;
    });
    if (stepController.value == 0.0) {
      startStepAnimation();
    } else {
      stepController.forward();
    }
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedSeconds++;
      });
    });
  }

  void pauseTimer() {
    timer?.cancel();
    stepController.stop(canceled: false);
    setState(() {
      isRunning = false;
    });
  }

  void startStepAnimation() {
    stepController.reset();
    if (!isRunning) return;
    final prevTime = currentStepIndex > 0
        ? brewStepTimes[currentStepIndex - 1]
        : 0;
    final stepDur = brewStepTimes[currentStepIndex] - prevTime;

    stepController
      ..duration = Duration(seconds: stepDur)
      ..reset()
      ..forward();
  }

  String formatTime(int totalSec) {
    final minutes = (totalSec ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSec % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void backStep(int time) {
    if (currentStepIndex <= 0) {
      setState(() {
        elapsedSeconds = 0;
        currentStepIndex = 0;
      });
      startStepAnimation();
    } else {
      setState(() {
        elapsedSeconds = time;
        currentStepIndex--;
      });
      startStepAnimation();
    }
  }

  void skipStep(int time) {
    setState(() {
      elapsedSeconds = time;
    });
    advanceStep();
  }

  void advanceStep() {
    if (currentStepIndex < brewStepTimes.length - 1) {
      setState(() => currentStepIndex++);
      startStepAnimation();
    } else {
      timer?.cancel();
      setState(() {
        isRunning = false;
        currentStepIndex++;
      });
      final draftEntry = JournalEntry(
        id: '',
        rating: 0,
        waterTemp: widget.recipe.waterTemp,
        timeTaken: widget.recipe.pourSteps.last,
        coffeeDose: widget.recipe.coffeeDose,
        waterWeightGrams: widget.recipe.waterWeightGrams,
        grindSetting: widget.recipe.grindSize,
        pourCount: widget.recipe.pourSteps.length,
        pourPattern: widget.recipe.pourAmounts.join(', '),
        notes: '',
        recipe: widget.recipe,
        recipeId: widget.recipe.name,
        date: DateTime.now(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddJournalEntryScreen(sourceEntry: draftEntry),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextBrewTime = currentStepIndex < brewStepTimes.length
        ? brewStepTimes[currentStepIndex]
        : 0;
    final nextBrewAmount = currentStepIndex < brewAmounts.length - 1
        ? brewAmounts[currentStepIndex + 1]
        : 0;

    final isDone = currentStepIndex >= brewStepTimes.length - 1;
    final pourInfo = isDone
        ? 'Final pour'
        : 'Next: ${nextBrewAmount}g at ${formatTime(nextBrewTime)}';

    final currentBrewAmount = currentStepIndex >= brewStepTimes.length
        ? 'Enjoy'
        : 'Pour to ${brewAmounts[currentStepIndex]}g';

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(title: const Text('V60 Brew Timer')),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSectionCard(
                  color: BUTTON_COLOR.withValues(alpha: 0.55),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final timerSize = constraints.maxWidth.clamp(
                            300.0,
                            340.0,
                          );

                          return SizedBox(
                            width: timerSize,
                            height: timerSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: AnimatedBuilder(
                                      animation: stepController,
                                      builder: (context, _) =>
                                          CircularProgressIndicator(
                                            value: stepController.value,
                                            strokeWidth: 18,
                                            backgroundColor: SURFACE_COLOR,
                                            color: PRIMARY_COLOR,
                                            strokeCap: StrokeCap.round,
                                          ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formatTime(elapsedSeconds),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(fontSize: 46),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentBrewAmount,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        pourInfo,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: MUTED_TEXT_COLOR,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: isRunning ? pauseTimer : startTimer,
                  icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(isRunning ? 'Pause' : 'Start'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Previous pour',
                      onPressed: () {
                        final time = currentStepIndex <= 1
                            ? 0
                            : brewStepTimes[currentStepIndex - 2];
                        backStep(time);
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 18),
                    IconButton.filledTonal(
                      tooltip: 'Next pour',
                      onPressed: () => skipStep(nextBrewTime),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
