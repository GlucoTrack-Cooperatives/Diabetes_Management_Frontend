import 'package:diabetes_management_system/main_navigation.dart';
import 'package:diabetes_management_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');

  // Show notification when app is in background or terminated
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'glucose_alerts',
    'Glucose Alerts',
    description: 'Critical glucose level notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Display the notification
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'glucose_alerts',
    'Glucose Alerts',
    channelDescription: 'Critical glucose level notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
    ticker: 'Glucose Alert',
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.critical,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await localNotifications.show(
    message.messageId.hashCode,
    message.notification?.title ?? 'Glucose Alert',
    message.notification?.body ?? 'Check your glucose levels',
    details,
    payload: message.data.toString(),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diabetes Management System',
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}