// lib/services/alarm_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzData;

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AlarmService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Call once in main()
  static Future<void> init() async {
    if (_initialized) return;
    tzData.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) async {
        print(
            '[AlarmService] Notification callback triggered. payload=${response.payload}');

        // helper: retry until navigator is available, then route to /home and push /alarm_ring
        Future<void> _ensureNavAndShow() async {
          const int maxAttempts = 12; // ~ up to 3s (12 * 250ms)
          int attempt = 0;
          while (attempt < maxAttempts) {
            final nav = appNavigatorKey.currentState;
            if (nav != null) {
              try {
                print(
                    '[AlarmService] Navigator found, routing to /home then /alarm_ring');

                // Clear stack and go to home first
                try {
                  nav.pushNamedAndRemoveUntil('/home', (route) => false);
                } catch (e) {
                  print('[AlarmService] pushNamedAndRemoveUntil failed: $e');
                  try {
                    nav.pushNamed('/home');
                  } catch (e2) {
                    print('[AlarmService] fallback push /home failed: $e2');
                  }
                }

                // small delay so Home can mount
                await Future.delayed(const Duration(milliseconds: 300));

                // push alarm screen on top
                try {
                  nav.pushNamed('/alarm_ring', arguments: response.payload);
                  print('[AlarmService] push /alarm_ring succeeded');
                } catch (e) {
                  print('[AlarmService] push /alarm_ring failed: $e');
                }
              } catch (e) {
                print('[AlarmService] Unexpected error routing: $e');
              }
              return;
            }

            // navigator not ready yet — wait & retry
            await Future.delayed(const Duration(milliseconds: 250));
            attempt += 1;
          }

          print(
              '[AlarmService] Navigator not available after retries — cannot open AlarmRingScreen now.');
        }

        // don't block plugin callback
        _ensureNavAndShow();
      },
    );

    // Create Android channel explicitly (ensures importance + full screen)
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    const channel = AndroidNotificationChannel(
      'alarm_channel', // id
      'Alarms', // name
      description: 'Alarm notifications',
      importance: Importance.max,
      playSound: true,
    );
    await androidImpl?.createNotificationChannel(channel);

    _initialized = true;
    print('[AlarmService] init done');
  }

  /// Schedule alarm
  /// - dateTime: target local DateTime
  /// - repeatDaily: nếu true thì lặp hàng ngày (match time)
  /// - soundRawName: tên file trong android res/raw (ví dụ 'drizzling' cho drizzling.mp3)
  /// - payload: bất kỳ chuỗi nào muốn truyền tới AlarmRingScreen
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    bool repeatDaily = false,
    String? soundRawName,
    String? payload,
  }) async {
    await init();

    final tzDate = tz.TZDateTime.from(dateTime, tz.local);

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: soundRawName != null,
      sound: soundRawName != null
          ? RawResourceAndroidNotificationSound(soundRawName)
          : null,
      ticker: 'Alarm',
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: soundRawName != null,
      sound: soundRawName != null ? '$soundRawName.aiff' : null,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (repeatDaily) {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    }

    print(
        '[AlarmService] Scheduled alarm id=$id at $dateTime (repeatDaily=$repeatDaily, sound=$soundRawName)');
  }

  static Future<void> cancelAlarm(int id) async {
    await _plugin.cancel(id);
    print('[AlarmService] Cancelled alarm id=$id');
  }
}
