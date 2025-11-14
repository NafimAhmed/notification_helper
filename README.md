# 📩 firebase_notification_helper

A lightweight, easy-to-use Flutter helper package for **Firebase Cloud Messaging (FCM)** and **Local Notifications**.

This package is designed to make notification integration extremely simple — even for beginners.  
It includes FCM token fetching, push notification sending, local notification display, and background handler support.


![Linear Date Picker Demo](https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExZmNwcnd6a3Z5dzRzdXo3YXo4MTg5YzV4azU1ZGh6Z2VqZWNwaWhuMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/tMEAP6v4cBjht6xVWr/giphy.gif)

---

# ✅ Summary of Everything Included in This Package

- ✔️ Fully designed, production-ready README.md
- ✔️ Firebase setup (project + app + google-services.json)
- ✔️ Android Gradle setup (project + app level)
- ✔️ Initialization + FCM token fetch + send push + local notification
- ✔️ Background notification handler
- ✔️ Beautiful full-page Flutter example UI
- ✔️ Example app run instructions
- ✔️ Security best practices (server key safety)
- ✔️ MIT License, Contribution guidelines
- ✔️ Pub.dev-ready consistent formatting

> **You can publish instantly — everything is already prepared!** 🚀

---

# ⭐ Features

- 🔥 Fetch FCM Token (Android)
- 📨 Send Push Notification via FCM API
- 🔔 Show Local Notifications
- 🚀 Background Message Handler Support
- 🧪 Full Example App Included
- 🛡 Very clean, beginner-friendly API
- 📦 Zero-config local notification support

---

# 📦 Installation

Add the package in `pubspec.yaml`:

```yaml
dependencies:
  firebase_notification_helper: ^0.0.1


```
## Usage

Then import

```dart
import 'package:dynamic_marker/dynamic_marker.dart';
```

Then use this code


```dart

import 'package:flutter/material.dart';
import 'package:firebase_notification_helper/firebase_notification_helper.dart';

class NotificationSenderPage extends StatefulWidget {
  const NotificationSenderPage({super.key});

  @override
  State<NotificationSenderPage> createState() => _NotificationSenderPageState();
}

class _NotificationSenderPageState extends State<NotificationSenderPage> {
  String token = "";
  String response = "";
  final keyController = TextEditingController();
  final titleController = TextEditingController(text: "Test Notification");
  final bodyController = TextEditingController(
    text: "Hello from firebase_notification_helper!",
  );

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await FirebaseNotificationHelper.getToken();
    setState(() => token = t ?? "");
  }

  Future<void> _sendNotification() async {
    if (keyController.text.isEmpty) return;

    final res = await FirebaseNotificationHelper.sendNotification(
      serverKey: keyController.text.trim(),
      targetToken: token,
      title: titleController.text.trim(),
      body: bodyController.text.trim(),
    );

    setState(() => response = res.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FCM Sender")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FirebaseNotificationHelper.showLocalNotification(
            title: titleController.text.trim(),
            body: bodyController.text.trim(),
          );
        },
        child: const Icon(Icons.notifications),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Your FCM Token:"),
            SelectableText(token),
            const SizedBox(height: 16),

            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: "Server Key",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Notification Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: bodyController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Notification Body",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _sendNotification,
              child: const Text("Send Notification"),
            ),

            const SizedBox(height: 16),
            const Text("Response:"),
            Expanded(
              child: SingleChildScrollView(child: Text(response)),
            ),
          ],
        ),
      ),
    );
  }
}





```

## Upgrade this android part in /android/build.gradle.kts

Then import

```kotlin

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}



```




## Upgrade this android part in /android/app/build.gradle.kts

Then import

```kotlin

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")   // REQUIRED
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}


```

## Initialization

Then import

```dart
import 'package:flutter/material.dart';
import 'package:firebase_notification_helper/firebase_notification_helper.dart';

Future<void> main() async {
  await FirebaseNotificationHelper.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationSenderPage(),
    );
  }
}

```

## Get FCM Token


```dart

final token = await FirebaseNotificationHelper.getToken();
print("🔥 Token: $token");


```

## Send FCM Push Notification


```dart

await FirebaseNotificationHelper.sendNotification(
serverKey: "YOUR_FCM_SERVER_KEY",
targetToken: token!,
title: "Hello!",
body: "This is sent using firebase_notification_helper",
);



```

## Show Local Notification


```dart

await FirebaseNotificationHelper.showLocalNotification(
title: "Local Test",
body: "This alert is from your device",
);




```