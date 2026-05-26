import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level function for background FCM handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to handle data while in the background, do it here.
  print("Handling a background message: ${message.messageId}");
}

class FCMService {
  FCMService._();
  static final FCMService instance = FCMService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inisialisasi Firebase Messaging & Local Notifications
  Future<void> init() async {
    if (_initialized) return;

    // 1. Minta Izin (Notification Permissions)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Local Notifications untuk memunculkan popup saat aplikasi sedang dibuka (Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // Channel khusus Android untuk memprioritaskan notifikasi (agar muncul pop-up)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Dengarkan Pesan Masuk (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    _initialized = true;
  }

  /// Ambil FCM Token untuk user saat ini (disimpan di Firestore nantinya)
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  // ===========================================================================
  // BAGIAN PENGIRIMAN NOTIFIKASI (SERVERLESS HTTP V1)
  // ===========================================================================

  Future<String> _getAccessToken() async {
    // 1. Baca file dari assets
    final jsonString = await rootBundle.loadString('lib/assets/secret/pet-shop-app-115fb-firebase-adminsdk-fbsvc-253fd21e4e.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);

    // 2. Tentukan scope untuk Firebase Messaging
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // 3. Dapatkan Auth Client
    final authClient = await clientViaServiceAccount(accountCredentials, scopes);
    
    // 4. Ambil token
    final token = authClient.credentials.accessToken.data;
    
    authClient.close();
    return token;
  }

  Future<String> _getProjectId() async {
    final jsonString = await rootBundle.loadString('lib/assets/secret/pet-shop-app-115fb-firebase-adminsdk-fbsvc-253fd21e4e.json');
    final data = jsonDecode(jsonString);
    return data['project_id'];
  }

  /// Fungsi utama untuk menembakkan notifikasi secara langsung ke device lain
  Future<void> sendNotification({
    required String targetFCMToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final token = await _getAccessToken();
      final projectId = await _getProjectId();

      final endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final messagePayload = {
        'message': {
          'token': targetFCMToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(messagePayload),
      );

      if (response.statusCode == 200) {
        print("FCM terkirim sukses!");
      } else {
        print("Gagal kirim FCM: ${response.body}");
      }
    } catch (e) {
      print("Error sendNotification FCM: $e");
    }
  }
}
