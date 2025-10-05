// lib/services/exam_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExamStorageService {
  static const String _examPrefix = 'exam_';

  // Save exam progress
  static Future<void> saveExamProgress({
    required String questionSetId,
    required String studentId,
    required int currentQuestionIndex,
    required List<int?> userAnswers,
    required List<String> questionStatus,
    required DateTime startTime,
    required int remainingSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_examPrefix}${questionSetId}_$studentId';

    final data = {
      'questionSetId': questionSetId,
      'studentId': studentId,
      'currentQuestionIndex': currentQuestionIndex,
      'userAnswers': userAnswers,
      'questionStatus': questionStatus,
      'startTime': startTime.toIso8601String(),
      'remainingSeconds': remainingSeconds,
      'lastSaved': DateTime.now().toIso8601String(),
    };

    await prefs.setString(key, json.encode(data));
  }

  // Load exam progress
  static Future<Map<String, dynamic>?> loadExamProgress({
    required String questionSetId,
    required String studentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_examPrefix}${questionSetId}_$studentId';
    final String? data = prefs.getString(key);

    if (data == null) return null;
    return json.decode(data);
  }

  // Clear exam progress
  static Future<void> clearExamProgress({
    required String questionSetId,
    required String studentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_examPrefix}${questionSetId}_$studentId';
    await prefs.remove(key);
  }

  // Check if exam is in progress
  static Future<bool> hasInProgressExam({
    required String questionSetId,
    required String studentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${questionSetId}_${studentId}_remaining_seconds';
    final savedSeconds = prefs.getInt(key);
    return savedSeconds != null && savedSeconds > 0;
  }
}
