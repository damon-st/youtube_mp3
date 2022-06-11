// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'damon', 'notifications',
    description: '',
    importance: Importance.low,
    playSound: false,
    enableVibration: false);

class NotificationService {
  static Future<void> initialize() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    const android = AndroidInitializationSettings("@mipmap/ic_launcher");
    const ios = IOSInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onSelectNotification: (String? payload) {
        print(payload);
      },
    );
  }
}
