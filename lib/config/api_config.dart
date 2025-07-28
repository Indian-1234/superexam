class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/';
  static const String login = '/institutions/loginstudent';
  static const String studentTests = '/student/tests';
  static const String startTest = '/student/test/{id}/start';
  static const String submitTest = '/student/test/{id}/submit';
}
