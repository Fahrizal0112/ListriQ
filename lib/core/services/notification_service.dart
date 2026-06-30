import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk notifikasi lokal.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Channel khusus untuk notifikasi prediksi.
  static const _channelId = 'listriq_prediction';
  static const _channelName = 'Prediksi Token';
  static const _channelDesc = 'Notifikasi saat token listrik hampir habis';

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Minta permission notifikasi (Android 13+).
    await requestNotificationPermission();

    // Pastikan channel notif dibuat (Android 8.0+).
    await _createChannel();
  }

  /// Request runtime permission notifikasi untuk Android 13+.
  static Future<void> requestNotificationPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  static Future<void> _createChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Tampilkan notifikasi prediktif.
  static Future<void> showPredictionNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: 0, // overwrite sebelumnya
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
