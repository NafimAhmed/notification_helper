import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 🔔 LOCAL NOTIFICATION
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 👉 Example er jonno: ekhane real key diba na.
/// User nijer project e nijer server key boshabe.
const String kDefaultServerKey = '<Cloud Messaging API (Legacy) Server key>';

// 🔔 Local notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 🔔 Notification channel (Android)
const AndroidNotificationChannel kHighImportanceChannel =
AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.high,
);

/// 🔹 Background message handler (top-level function হতে হবে)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 BG Message: ${message.messageId}');
  debugPrint('🔔 BG Title: ${message.notification?.title}');
  debugPrint('🔔 BG Body : ${message.notification?.body}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp();

  // FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔔 Local notification init
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 🔔 Create notification channel (Android 8+)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(kHighImportanceChannel);

  runApp(const FcmTokenSenderApp());
}

class FcmTokenSenderApp extends StatelessWidget {
  const FcmTokenSenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Token Sender Example',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF7A00),
      ),
      debugShowCheckedModeBanner: false,
      home: const FcmSenderHome(),
    );
  }
}

class FcmSenderHome extends StatefulWidget {
  const FcmSenderHome({super.key});

  @override
  State<FcmSenderHome> createState() => _FcmSenderHomeState();
}

class _FcmSenderHomeState extends State<FcmSenderHome> {
  final TextEditingController _serverKeyCtrl =
  TextEditingController(text: kDefaultServerKey);

  final TextEditingController _tokenCtrl = TextEditingController();
  final TextEditingController _titleCtrl =
  TextEditingController(text: 'Test Notification');
  final TextEditingController _bodyCtrl = TextEditingController(
      text: 'এই notification টা FCM token দিয়ে পাঠানো হয়েছে 🙂');

  bool _isSending = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    // 🔹 Notification permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔔 User granted permission: ${settings.authorizationStatus}');

    // 🔹 Foreground message listener → LOCAL NOTIFICATION দেখাবে
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('📩 FG Message: ${message.messageId}');
      debugPrint('📩 FG Title: ${message.notification?.title}');
      debugPrint('📩 FG Body : ${message.notification?.body}');

      final notification = message.notification;
      if (notification != null) {
        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title ?? 'FCM Message',
          notification.body ?? '',
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

    // 🔹 FCM Token console + UI তে দেখানো
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('🔥 FCM Token: $token');

      if (mounted) {
        setState(() {
          _tokenCtrl.text = token ?? '';
        });
      }
    } catch (e) {
      debugPrint('❌ Token fetch error: $e');
    }
  }

  @override
  void dispose() {
    _serverKeyCtrl.dispose();
    _tokenCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  /// 🔔 শুধু লোকাল test notification দেখানোর জন্য
  Future<void> _showLocalNotification() async {
    final title = _titleCtrl.text.trim().isEmpty
        ? 'Local Notification'
        : _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim().isEmpty
        ? 'This is a local test notification.'
        : _bodyCtrl.text.trim();

    await flutterLocalNotificationsPlugin.show(
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

  Future<void> _send() async {
    final serverKey = _serverKeyCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    final title =
    _titleCtrl.text.trim().isEmpty ? 'Notification' : _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (serverKey.isEmpty) {
      setState(() => _result = '❌ আগে উপরে FCM Server key বসাও');
      return;
    }
    if (token.isEmpty) {
      setState(() => _result = '❌ আগে target device er FCM token লিখো');
      return;
    }

    setState(() {
      _isSending = true;
      _result = null;
    });

    try {
      final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };

      final payload = {
        'to': token,
        'priority': 'high',
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'sender': 'firebase_notification_helper_example',
        },
      };

      final resp =
      await http.post(url, headers: headers, body: jsonEncode(payload));

      String text = 'HTTP ${resp.statusCode}\n';
      try {
        final jsonBody = jsonDecode(resp.body);
        text += const JsonEncoder.withIndent('  ').convert(jsonBody);
      } catch (_) {
        text += resp.body;
      }

      setState(() {
        _result = text;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
          }
      }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token Sender (Example)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLocalNotification,
        child: const Icon(Icons.notifications),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 16 + pad.top, 16, 16 + pad.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FCM Server Key:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _serverKeyCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'YOUR_FCM_SERVER_KEY_HERE',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'Target Device FCM Token:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'এখানে টার্গেট ডিভাইসের FCM token paste করো',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Notification Title:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Title',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notification Body:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Body',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSending ? 'Sending...' : 'Send Notification',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'FCM Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                constraints:
                const BoxConstraints(minHeight: 80, maxHeight: 240),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result ??
                        'এখানে FCM server এর response দেখাবে (success / error)...',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
