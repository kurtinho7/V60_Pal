import 'package:flutter/material.dart';
import 'package:v60pal/BrewTimerPage.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/main.dart';
import 'package:v60pal/models/Recipe.dart';
import 'dart:async';
import 'package:v60pal/PostTimerScreen.dart';

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
          // when the circle fills, we've reached end of this step
          advanceStep(
            //brewAmounts[currentStepIndex],
            //brewStepTimes[currentStepIndex],
          );
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
    timer = Timer.periodic(Duration(seconds: 1), (_) {
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
      //stepController.reset();
      startStepAnimation();
    } else {
      setState(() {
        elapsedSeconds = time;
        currentStepIndex--;
      });
      //stepController.reset();
      startStepAnimation();
    }
  }

  void skipStep(int time) {
    setState(() {
      elapsedSeconds = time;
    });
    //stepController.reset();
    advanceStep();
  }

  void advanceStep() {
    if (currentStepIndex < brewStepTimes.length - 1) {
      setState(() => currentStepIndex++);
      startStepAnimation();
    } else {
      // all done
      timer?.cancel();
      setState(() {
        isRunning = false;
        currentStepIndex++;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostTimerScreen(recipe: widget.recipe),
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
        ? ''
        : 'Next: $nextBrewAmount g @ ${formatTime(nextBrewTime)}';

    final currentBrewAmount = currentStepIndex >= brewStepTimes.length
        ? 'Enjoy!'
        : 'Pour to ${brewAmounts[currentStepIndex]}g';

    return Scaffold(
      appBar: AppBar(title: Text("V60 Brew Timer"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated circle
            SizedBox(
              width: 300,
              height: 300,
              child: AnimatedBuilder(
                animation: stepController,
                builder: (context, _) => CircularProgressIndicator(
                  value: stepController.value,
                  strokeWidth: 20,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Elapsed timer
            Text(
              formatTime(elapsedSeconds),
              style: TextStyle(fontSize: 48, color: TEXT_COLOR),
            ),
            SizedBox(height: 12),
            Text(
              currentBrewAmount,
              style: TextStyle(fontSize: 18.0, color: TEXT_COLOR),
            ),
            SizedBox(height: 12),
            // Next pour info
            Text(
              pourInfo,
              style: TextStyle(fontSize: 18.0, color: Colors.white70),
            ),
            SizedBox(height: 24),
            // Start/pause
            ElevatedButton(
              onPressed: isRunning ? pauseTimer : startTimer,
              child: Text(isRunning ? "Pause" : "Start"),
            ),
            SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    int time = 0;
                    if (currentStepIndex <= 1) {
                      time = 0;
                    } else {
                      time = brewStepTimes[currentStepIndex - 2];
                    }
                    backStep(time);
                  },
                  child: Icon(Icons.arrow_back),
                  style: ButtonStyle(
                    fixedSize: WidgetStateProperty.all(const Size(70, 80)),
                  ),
                ),
                SizedBox(width: 50),
                ElevatedButton(
                  onPressed: () => skipStep(nextBrewTime),
                  child: Icon(Icons.arrow_forward),
                  style: ButtonStyle(
                    fixedSize: WidgetStateProperty.all(const Size(70, 80)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
