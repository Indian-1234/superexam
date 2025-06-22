// firebase_messaging_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Initialize Firebase Messaging
  static Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission();
    
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings();
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(settings);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');
    
    // Check if it's an OTP message
    if (message.data['type'] == 'otp') {
      String otp = message.data['otp'] ?? '';
      String phoneNumber = message.data['phoneNumber'] ?? '';
      
      // You can auto-fill OTP here or show a notification
      _showOTPNotification(otp, phoneNumber);
    }
  }

  // Show OTP notification
  static Future<void> _showOTPNotification(String otp, String phoneNumber) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'otp_channel',
      'OTP Notifications',
      channelDescription: 'Channel for OTP notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _localNotifications.show(
      0,
      'OTP Received',
      'Your OTP is: $otp',
      notificationDetails,
    );
  }
}

// Background message handler (must be top-level function)
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}');
}