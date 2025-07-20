import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superexam/message/firebase_messaging_service.dart';
import 'package:superexam/screens/exam/exam_screen.dart';
import 'package:superexam/widgets/app_background.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_dashboard_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  if (kDebugMode) {
    print('=== APP INITIALIZATION STARTED ===');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for proper status bar appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // Manual Firebase Initialization
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDjPIAoNnRkbKYdgNBvDD1a2oudWt1-qCg",
        appId: "1:1089178565344:android:c17718cbc202668088ee85",
        messagingSenderId: "1089178565344",
        projectId: "exam-f77f4",
        storageBucket: "exam-f77f4.firebasestorage.app",
      ),
    );

    if (kDebugMode) {
      print('✅ Firebase initialized manually');
    }

    await FirebaseMessagingService.initialize();
    String? fcmToken = await FirebaseMessagingService.getToken();
    if (kDebugMode) {
      print('🎯 FCM Token for testing: $fcmToken');
    }
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // Add a pause for initialization
  if (kDebugMode) {
    print('⏳ Pausing for 2 seconds...');
    await Future.delayed(const Duration(seconds: 2));
    print('▶️ Resuming app launch');
  }

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
      home: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: AppInitializer(),
      ),
      routes: {
        '/welcome': (context) => const AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
              child: WelcomeScreen(),
            ),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/exam':
            return MaterialPageRoute(
              builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
                child: FutureBuilder<String?>(
                  future: UserSession.getUserId(),
                  builder: (context, snapshot) {
                    final studentId = snapshot.data ?? '';
                    return ExamScreen(
                      examTitle: 'realExam',
                      questionSetId: '',
                      studentId: studentId,
                    );
                  },
                ),
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  String? _userName;
  String? _userId;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (_isLoggedIn) {
        _userName = prefs.getString('userName') ?? 'Student';
        _userId = prefs.getString('userId') ?? '';

        if (kDebugMode) {
          print('✅ User is logged in: $_userName ($_userId)');
        }
      } else {
        if (kDebugMode) {
          print('❌ User not logged in');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking login status: $e');
      }
      _isLoggedIn = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing App...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Navigate based on login status
    if (_isLoggedIn && _userName != null) {
      return HomeDashboardScreen(username: _userName!, studentId: _userId!);
    } else {
      return const WelcomeScreen();
    }
  }
}

// Helper class for managing user session
class UserSession {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserName = 'userName';
  static const String _keyUserId = 'userId';

  // Save login session
  static Future<void> saveLoginSession({
    required String userName,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserId, userId);

    if (kDebugMode) {
      print('✅ Login session saved for: $userName');
    }
  }

  // Get current user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Get current user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Navigate to exam screen with dynamic student ID and screenshot prevention
  static Future<void> navigateToExam(
    BuildContext context, {
    String examTitle = 'realExam',
    String questionSetId = '',
  }) async {
    final studentId = await getUserId() ?? '';

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            child: ExamScreen(
              examTitle: examTitle,
              questionSetId: questionSetId,
              studentId: studentId,
            ),
          ),
        ),
      );
    }
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserId);

    if (kDebugMode) {
      print('✅ User logged out successfully');
    }
  }
}
