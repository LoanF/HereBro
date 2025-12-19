import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService() {
    init();
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'herebro_channel',
      'HereBro Notifications',
      description: 'Notifications de HereBro',
      importance: Importance.max,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];

    if (type == 'friend_accept') {
      _showNotification(
        title: 'Demande acceptée',
        body:
            message.notification?.body ?? 'Votre demande d’ami a été acceptée',
      );
      return;
    }

    if (type == 'friend_refuse') {
      _showNotification(
        title: 'Demande refusée',
        body: message.notification?.body ?? 'Votre demande d’ami a été refusée',
      );
      return;
    }

    // fallback (autres notifications)
    if (message.notification != null) {
      _showNotification(
        title: message.notification!.title,
        body: message.notification!.body,
      );
    }
  }

  Future<void> _showNotification({String? title, String? body}) async {
    const androidDetails = AndroidNotificationDetails(
      'herebro_channel',
      'HereBro Notifications',
      channelDescription: 'Notifications de HereBro',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
