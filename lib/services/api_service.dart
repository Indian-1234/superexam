import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/test_model.dart';

class ApiService {
  final String token;

  ApiService({required this.token});

  Future<List<Test>> getAvailableTests() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.studentTests}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> testsJson = jsonDecode(response.body)['data'];
      return testsJson.map((json) => Test.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tests');
    }
  }

  Future<List<Question>> startTest(String testId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.startTest.replaceAll('{id}', testId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> questionsJson = jsonDecode(response.body)['data']['questions'];
      return questionsJson.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception('Failed to start test');
    }
  }

  Future<Map<String, dynamic>> submitTest(String testId, List<Map<String, dynamic>> answers) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.submitTest.replaceAll('{id}', testId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'answers': answers,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Failed to submit test');
    }
  }
}
