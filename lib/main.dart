import 'package:flutter/material.dart';
import 'package:superexam/screens/exam/exam_screen.dart';
import 'package:superexam/widgets/app_background.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_dashboard_screen.dart';
import 'utils/theme.dart';
// import 'widgets/app_background.dart'; // We'll create this file

void main() {
  runApp(const ExamApp());
}

class ExamApp extends StatelessWidget {
  const ExamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        // This builder wraps every screen with our background
        return AppBackground(child: child!);
      },
      home: const WelcomeScreen(),
      routes: {
        '/exam': (context) => const ExamScreen(examTitle: 'realExam', questionSetId: '', studentId: '',),
        '/home': (context) => const HomeDashboardScreen(username: 'Murugan'),
      },
    );
  }
}