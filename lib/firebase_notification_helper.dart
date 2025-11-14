// lib/firebase_notification_helper.dart
// A reusable Flutter package to simplify Firebase Messaging + Local Notifications
// Package Name: firebase_notification_helper

library firebase_notification_helper;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// -----------------------------------------------------------------------------
// 🔔 Local Notifications
// -----------------------------------------------------------------------------
final FlutterLocalNotificationsPlugin _local =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.high,
);

bool _initialized = false;

// -----------------------------------------------------------------------------
// 🔥 Main Helper Class
// -----------------------------------------------------------------------------
class FirebaseNotificationHelper {
  const FirebaseNotificationHelper._(); // no instance

  /// MUST be called inside main() before runApp()
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   await FirebaseNotificationHelper.initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseBgHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground FCM → Local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        _local.show(
          n.hashCode,
          n.title ?? 'FCM Message',
          n.body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  // 🔥 Get FCM token
  static Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }

  // 🔔 Local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // 📤 Send FCM Legacy notification
  //
  // SECURITY WARNING:
  // Do NOT ship serverKey in production/public apps.
  static Future<FcmResult> sendNotification({
    required String serverKey,
    required String targetToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final payload = {
      'to': targetToken,
      'priority': 'high',
      'notification': {
        'title': title,
        'body': body,
      },
      'data': {
        'sender': 'firebase_notification_helper',
        if (data != null) ...data,
      }
    };

    final resp =
    await http.post(url, headers: headers, body: jsonEncode(payload));

    dynamic parsed;
    try {
      parsed = jsonDecode(resp.body);
    } catch (_) {
      parsed = resp.body;
    }

    return FcmResult(
      statusCode: resp.statusCode,
      rawBody: resp.body,
      parsedBody: parsed,
    );
  }
}

// -----------------------------------------------------------------------------
// Background Handler
// -----------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseBgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("[BG] Title: ${message.notification?.title}");
}

// -----------------------------------------------------------------------------
// Result Model
// -----------------------------------------------------------------------------
class FcmResult {
  final int statusCode;
  final dynamic parsedBody;
  final String rawBody;

  const FcmResult({
    required this.statusCode,
    required this.parsedBody,
    required this.rawBody,
  });

  bool get success => statusCode == 200;

  @override
  String toString() => 'FcmResult(code: $statusCode, body: $parsedBody)';
}

