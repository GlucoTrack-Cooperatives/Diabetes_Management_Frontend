import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

// Provider for FCM Service
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(apiClientProvider));
});

/// Service to handle Firebase Cloud Messaging (FCM) tokens and notifications
class FcmService {
  final ApiClient _apiClient;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FcmService(this._apiClient);

  /// Initialize FCM: Request permissions and setup listeners
  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permission for notifications (iOS and web)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permission');
      }
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('User granted provisional notification permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted notification permission');
      }
    }

    // Handle foreground messages (when app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM Token refreshed: $newToken');
      }
      // Automatically register the new token
      registerToken(newToken);
    });
  }

  /// Get the current FCM token from Firebase
  Future<String?> getToken() async {
    try {
      String? token;

      // For web, we need to provide VAPID key
      if (kIsWeb) {
        // IMPORTANT: Replace this with your actual VAPID key from Firebase Console
        // Go to: Firebase Console > Project Settings > Cloud Messaging > Web Push certificates
        // Generate a new key pair if you don't have one
        const String vapidKey = 'YOUR_VAPID_KEY_HERE';

        // For now, get token without VAPID (will need to be configured)
        token = await _firebaseMessaging.getToken(
          vapidKey: vapidKey.contains('YOUR_VAPID') ? null : vapidKey,
        );
      } else {
        // For mobile platforms (Android/iOS)
        token = await _firebaseMessaging.getToken();
      }

      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Register FCM token with backend
  /// Call this after successful login
  Future<void> registerToken([String? token]) async {
    try {
      // If no token provided, get it from Firebase
      token ??= await getToken();

      if (token == null) {
        if (kDebugMode) {
          print('No FCM token available to register');
        }
        return;
      }

      // Send token to backend
      await _apiClient.post('/fcm-tokens/register', {'token': token});

      if (kDebugMode) {
        print('Successfully registered FCM token with backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token: $e');
      }
      // Don't throw error - notification registration should not block login
    }
  }

  /// Unregister FCM token from backend
  /// Call this on logout
  Future<void> unregisterToken() async {
    try {
      String? token = await getToken();
      if (token == null) return;

      await _apiClient.delete('/fcm-tokens/unregister', {'token': token});

      if (kDebugMode) {
        print('Successfully unregistered FCM token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unregistering FCM token: $e');
      }
      // Don't throw error - continue with logout even if this fails
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create high-priority notification channel for glucose alerts (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'glucose_alerts', // id
      'Glucose Alerts', // name
      description: 'Critical glucose level notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // 2. Create channel for Chat Messages
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(channel);
    await platform?.createNotificationChannel(chatChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (kDebugMode) {
      print('Local notifications initialized');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    // Extract type from data if available, default to 'alert'
    final String type = message.data['type'] ?? 'alert';

    String title = message.notification?.title ?? 'New Notification';
    String body = message.notification?.body ?? '';

    _showLocalNotification(
      title: title,
      body: body,
      payload: message.data.toString(),
      channelId: type == 'chat' ? 'chat_messages' : 'glucose_alerts',
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'glucose_alerts',
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'chat_messages' ? 'Chat Messages' : 'Glucose Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      details,
      payload: payload,
    );

    if (kDebugMode) {
      print('Local notification displayed: $title');
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    // TODO: Navigate to relevant screen (e.g., glucose alerts page)
  }

  /// Handle notification tap (when user taps FCM notification from background)
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('FCM Notification tapped:');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // TODO: Navigate to relevant screen based on message data
    // For example, navigate to glucose alerts screen
  }
}