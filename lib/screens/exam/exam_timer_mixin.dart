import 'dart:async';
import 'package:flutter/material.dart';

mixin ExamTimerMixin<T extends StatefulWidget> on State<T> {
  DateTime? startTime;
  DateTime? endTime;
  Timer? examTimer;
  Duration remainingTime = Duration(hours: 1);
  
  void Function()? onTimeUp;
  
  String get timerDisplay {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  bool get isTimeRunningOut => remainingTime.inMinutes <= 5;
  
  void initializeTimer({Duration? duration, void Function()? onTimeUpCallback}) {
    startTime = DateTime.now();
    if (duration != null) {
      remainingTime = duration;
    }
    onTimeUp = onTimeUpCallback;
    _startTimer();
  }
  
  void _startTimer() {
    examTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingTime.inSeconds > 0) {
            remainingTime = remainingTime - Duration(seconds: 1);
          } else {
            timer.cancel();
            endTime = DateTime.now();
            if (onTimeUp != null) {
              onTimeUp!();
            }
          }
        });
      }
    });
  }
  
  void stopTimer() {
    endTime = DateTime.now();
    examTimer?.cancel();
  }
  
  Widget buildTimerWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isTimeRunningOut ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTimeRunningOut ? Colors.red : Colors.green,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: isTimeRunningOut ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            timerDisplay,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isTimeRunningOut ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  Map<String, String> getTimeData() {
    return {
      'startTime': startTime?.toIso8601String() ?? '',
      'endTime': (endTime ?? DateTime.now()).toIso8601String(),
    };
  }
  
  @override
  void dispose() {
    examTimer?.cancel();
    super.dispose();
  }
}