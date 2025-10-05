import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> initializeTimer(
      {Duration? duration,
      void Function()? onTimeUpCallback,
      String? examKey}) async {
    startTime = DateTime.now();
    if (examKey != null) {
      final savedTime = await loadSavedTime(examKey);
      if (savedTime != null) {
        duration = savedTime;
      }
    }
    if (duration != null) {
      remainingTime = duration;
    }
    onTimeUp = onTimeUpCallback;
    _startTimer(examKey);
  }

  void _startTimer([String? examKey]) {
    examTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingTime.inSeconds > 0) {
            remainingTime = remainingTime - Duration(seconds: 1);
            if (examKey != null) {
              saveTimerState(examKey);
            }
          } else {
            timer.cancel();
            endTime = DateTime.now();
            if (examKey != null) {
              clearTimerState(examKey);
            }
            if (onTimeUp != null) {
              onTimeUp!();
            }
          }
        });
      }
    });
  }

  Future<void> stopTimer([String? examKey]) async {
    endTime = DateTime.now();
    examTimer?.cancel();
    if (examKey != null) {
      await clearTimerState(examKey);
    }
  }

  Future<Duration?> loadSavedTime(String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeconds = prefs.getInt('${examKey}_remaining_seconds');
    if (savedSeconds != null && savedSeconds > 0) {
      return Duration(seconds: savedSeconds);
    }
    return null;
  }

  Future<void> saveTimerState(String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${examKey}_remaining_seconds', remainingTime.inSeconds);
  }

  Future<void> clearTimerState(String examKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${examKey}_remaining_seconds');
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
