// firebase_messaging_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
       FlutterLocalNotificationsPlugin();

  // Initialize Firebase Messaging with comprehensive logging
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('=== FIREBASE MESSAGING INITIALIZATION STARTED ===');
    }
    
    try {
      // Request permission
      if (kDebugMode) {
        print('📱 Requesting notification permissions...');
      }
      
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );
      
      if (kDebugMode) {
        print('✅ Permission status: ${settings.authorizationStatus}');
        print('Alert: ${settings.alert}');
        print('Badge: ${settings.badge}');
        print('Sound: ${settings.sound}');
      }

      // Initialize local notifications
      if (kDebugMode) {
        print('🔔 Initializing local notifications...');
      }
      
      const AndroidInitializationSettings androidSettings =
           AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
           DarwinInitializationSettings(
             requestAlertPermission: true,
             requestBadgePermission: true,
             requestSoundPermission: true,
           );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      bool? initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) {
            print('📱 Local notification tapped: ${response.payload}');
          }
        },
      );
      
      if (kDebugMode) {
        print('✅ Local notifications initialized: $initialized');
      }

      // Create notification channel for Android
      await _createNotificationChannel();

      // Handle foreground messages
      if (kDebugMode) {
        print('📥 Setting up foreground message handler...');
      }
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      if (kDebugMode) {
        print('📥 Setting up background message handler...');
      }
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('📱 App opened from notification: ${message.messageId}');
          print('Notification data: ${message.data}');
        }
      });

      // Check if app was opened from a terminated state
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('📱 App opened from terminated state via notification');
          print('Initial message: ${initialMessage.data}');
        }
      }

      if (kDebugMode) {
        print('=== FIREBASE MESSAGING INITIALIZATION COMPLETED ===');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ FIREBASE MESSAGING INITIALIZATION FAILED');
        print('Error: $e');
      }
    }
  }

  // Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'otp_channel',
      'OTP Notifications',
      description: 'Channel for OTP notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    if (kDebugMode) {
      print('✅ Android notification channel created: ${channel.id}');
    }
  }

  // Get FCM token with logging
  static Future<String?> getToken() async {
    if (kDebugMode) {
      print('=== FCM TOKEN RETRIEVAL STARTED ===');
    }
    
    try {
      String? token = await _firebaseMessaging.getToken();
      
      if (kDebugMode) {
        print('✅ FCM Token retrieved successfully');
        print('Token length: ${token?.length ?? 0}');
        print('FCM Token: $token');
        print('=== FCM TOKEN RETRIEVAL COMPLETED ===');
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('🔄 FCM Token refreshed: $newToken');
        }
      });
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM TOKEN RETRIEVAL FAILED');
        print('Error: $e');
        print('=== FCM TOKEN RETRIEVAL FAILED ===');
      }
      return null;
    }
  }

  // Handle foreground messages with comprehensive logging
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('=== FOREGROUND MESSAGE RECEIVED ===');
      print('Message ID: ${message.messageId}');
      print('From: ${message.from}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('Timestamp: ${DateTime.now().toIso8601String()}');
    }

    // Check if it's an OTP message
    if (message.data['type'] == 'otp') {
      String otp = message.data['otp'] ?? '';
      String phoneNumber = message.data['phoneNumber'] ?? '';
      
      if (kDebugMode) {
        print('🔐 OTP Message detected');
        print('OTP: $otp');
        print('Phone: $phoneNumber');
      }

      // Show local notification for OTP
      await _showOTPNotification(otp, phoneNumber);
    }
    
    if (kDebugMode) {
      print('=== FOREGROUND MESSAGE HANDLED ===');
    }
  }

  // Show OTP notification with logging
  static Future<void> _showOTPNotification(String otp, String phoneNumber) async {
    if (kDebugMode) {
      print('=== SHOWING OTP NOTIFICATION ===');
      print('OTP: $otp');
      print('Phone: $phoneNumber');
    }
    
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'otp_channel',
        'OTP Notifications',
        channelDescription: 'Channel for OTP notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().microsecondsSinceEpoch ~/ 1000000,
        'Adityan Academy OTP',
        'Your verification code is: $otp',
        notificationDetails,
        payload: 'otp:$otp:$phoneNumber',
      );
      
      if (kDebugMode) {
        print('✅ OTP notification shown successfully');
        print('=== OTP NOTIFICATION COMPLETED ===');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show OTP notification');
        print('Error: $e');
      }
    }
  }
}

// Background message handler (must be top-level function)
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
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
    print('=== BACKGROUND MESSAGE RECEIVED ===');
    print('Message ID: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('=== BACKGROUND MESSAGE HANDLED ===');
  }
}