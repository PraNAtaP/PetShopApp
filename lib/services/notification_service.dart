import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../core/theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized before accessing services in background
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

/// A singleton service to manage Firebase Cloud Messaging and Local Notifications.
class NotificationService {
  NotificationService._privateConstructor();
  
  static final NotificationService instance = NotificationService._privateConstructor();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initializes the notification service. Must be called in main.dart after Firebase.initializeApp().
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await instance._initLocalNotifications();
    instance._setupForegroundMessaging();
  }

  /// Sets up flutter_local_notifications for foreground notifications.
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Using DarwinInitializationSettings for iOS
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap when the app is in the foreground
        debugPrint('Notification tapped in foreground: ${response.payload}');
      },
    );

    // Create the high importance channel for Android Heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Requests permission from the user to display notifications.
  Future<void> requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized || 
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted permission');
      await getToken();
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// Retrieves the unique FCM device token and saves it to Firestore if the user is authenticated.
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      
      print('\n=============================================');
      print('FCM TOKEN: $token');
      print('=============================================\n');
      
      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Save the token to the users collection
          await FirestoreService.instance.updateUserFcmToken(user.uid, token);
        }
      }
      
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Configures listening to message streams when the app is in foreground and
  /// when opening the app from a terminated/background state.
  void _setupForegroundMessaging() {
    // Listen for messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              color: AppColors.primary,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // Handle when a user taps a notification while the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Navigate or handle your routing here based on message.data
    });

    // Handle case where app was terminated and opened via a notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App launched from terminated state via message!');
        // Navigate or handle routing here
      }
    });
  }
}
