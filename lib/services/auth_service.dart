import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<User> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'email': username,
      'password': password,
    });

    // 🔍 Console logs for debugging
    print('📡 Requesting: $url');
    print('🧾 Headers: $headers');
    print('📤 Request Body: $body');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        print('✅ Login Successful: $data');
        return User.fromJson(data);
      } else {
        throw Exception('❌ Login failed: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error during login: $e');
      rethrow;
    }
  }
}
