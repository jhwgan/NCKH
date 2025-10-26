// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tzData;

// final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// class AlarmService {
//   static final FlutterLocalNotificationsPlugin _plugin =
//       FlutterLocalNotificationsPlugin();
//   static bool _initialized = false;

//   /// Call once in main()
//   static Future<void> init() async {
//     if (_initialized) return;
//     tzData.initializeTimeZones();

//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosInit = DarwinInitializationSettings();

//     await _plugin.initialize(
//       const InitializationSettings(android: androidInit, iOS: iosInit),
//       onDidReceiveNotificationResponse: (response) async {
//         print(
//             '[AlarmService] Notification callback triggered. payload=${response.payload}');

//         // helper: retry until navigator is available, then route to /home and push /alarm_ring
//         Future<void> _ensureNavAndShow() async {
//           const int maxAttempts = 12; // ~3s
//           int attempt = 0;
//           while (attempt < maxAttempts) {
//             final nav = appNavigatorKey.currentState;
//             if (nav != null) {
//               try {
//                 print(
//                     '[AlarmService] Navigator found, routing to /home then /alarm_ring');
//                 nav.pushNamedAndRemoveUntil('/home', (route) => false);
//                 await Future.delayed(const Duration(milliseconds: 300));
//                 nav.pushNamed('/alarm_ring', arguments: response.payload);
//               } catch (e) {
//                 print('[AlarmService] Navigation error: $e');
//               }
//               return;
//             }
//             await Future.delayed(const Duration(milliseconds: 250));
//             attempt += 1;
//           }
//           print(
//               '[AlarmService] Navigator not available after retries — cannot open AlarmRingScreen.');
//         }

//         _ensureNavAndShow();
//       },
//     );

//     _initialized = true;
//     print('[AlarmService] init done');
//   }

//   /// --- Helpers ---

//   static DateTime _nextTrigger(DateTime t) {
//     final now = DateTime.now();
//     var trigger = DateTime(now.year, now.month, now.day, t.hour, t.minute, 0);
//     if (!trigger.isAfter(now)) trigger = trigger.add(const Duration(days: 1));
//     return trigger;
//   }

//   static Future<void> _ensureChannel({String? soundRawName}) async {
//     final androidImpl = _plugin.resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>();

//     final chId = 'alarm_${(soundRawName ?? 'default').toLowerCase()}_v1';
//     final chName = 'Alarms – ${(soundRawName ?? 'default')}';

//     final channel = AndroidNotificationChannel(
//       chId,
//       chName,
//       description: 'Alarm notifications',
//       importance: Importance.max,
//       playSound: true,
//       sound: soundRawName != null
//           ? RawResourceAndroidNotificationSound(soundRawName)
//           : null,
//       audioAttributesUsage: AudioAttributesUsage.alarm,
//     );

//     await androidImpl?.createNotificationChannel(channel);
//   }

//   /// --- Main APIs ---

//   static Future<void> scheduleAlarm({
//     required int id,
//     required DateTime dateTime,
//     required String title,
//     required String body,
//     bool repeatDaily = false,
//     String? soundRawName,
//     String? payload,
//   }) async {
//     await init();
//     await _ensureChannel(soundRawName: soundRawName);

//     final chId = 'alarm_${(soundRawName ?? 'default').toLowerCase()}_v1';
//     final when = repeatDaily ? dateTime : _nextTrigger(dateTime);
//     final tzDate = tz.TZDateTime.from(when, tz.local);

//     final androidDetails = AndroidNotificationDetails(
//       chId,
//       'Alarms',
//       channelDescription: 'Alarm notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       fullScreenIntent: true,
//       playSound: true,
//       category: AndroidNotificationCategory.alarm,
//       ticker: 'Alarm',
//     );

//     final iosDetails = DarwinNotificationDetails(
//       presentSound: soundRawName != null,
//       sound: soundRawName != null ? '$soundRawName.aiff' : null,
//     );

//     final details =
//         NotificationDetails(android: androidDetails, iOS: iosDetails);

//     await _plugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tzDate,
//       details,
//       payload: payload,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
//     );

//     print('[AlarmService] Scheduled alarm id=$id at $when '
//         '(repeatDaily=$repeatDaily, sound=$soundRawName, channel=$chId)');
//   }

//   static Future<void> cancelAlarm(int id) async {
//     await _plugin.cancel(id);
//     print('[AlarmService] Cancelled alarm id=$id');
//   }
// }
// lib/services/alarm_service.dart
// 👉 REPLACE toàn bộ nội dung file này

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../main.dart'; // để dùng appNavigatorKey

/// Tên kênh cố định cho báo thức
const String _alarmChannelId = 'alarm_channel_v3';
const String _alarmChannelName = 'Alarm';
const String _alarmChannelDesc = 'Alarms and wakeups';

/// Plugin dùng chung
final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

/// -------------------------------
/// 1) BACKGROUND HANDLERS (Top-level)
/// -------------------------------

/// Handler khi người dùng tương tác notification ở NỀN (app terminated/background).
/// Phải là hàm top-level + có @pragma để không bị tree-shake.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Lưu ý: ở nền, KHÔNG có context. Chỉ làm nhẹ: log, hoặc enqueue.
  // Điều hướng thực sự sẽ làm ở AlarmService._maybeAutoRouteFromLaunch() sau khi engine sẵn sàng.
  debugPrint('notificationTapBackground payload=${response.payload}');
}

/// -------------------------------
/// 2) AlarmService API
/// -------------------------------
class AlarmService {
  /// Gọi trong main() trước khi runApp
  static Future<void> init() async {
    // 2.1 TZ data
    tz.initializeTimeZones();
    // Nếu cần vùng giờ VN: Asia/Ho_Chi_Minh
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // 2.2 Android init settings
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      // iOS/macOS nếu cần có thể thêm sau
    );

    // 2.3 Khởi tạo plugin + callback foreground & background
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      debugPrint('[AlarmService] notification permission: $result');
    }

    // 2.4 Nếu app được MỞ DO NOTIFICATION → tự điều hướng tới màn chuông
    await _maybeAutoRouteFromLaunch();

    // 2.5 Tạo sẵn kênh báo thức có âm thanh (để đảm bảo “kêu ngay khi nổ”)
    await _ensureAlarmChannelWithSound(soundRawName: 'drizzling');
  }

  /// Lập một báo thức tại thời điểm cụ thể (local time), có thể kèm âm thanh raw
  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTimeLocal, // thời điểm local
    String? payload, // ví dụ: tên bài nhạc, id báo thức...
    String soundRawName =
        'drizzling', // tên file trong res/raw (không phần mở rộng)
    bool allowWhileIdle = true,
  }) async {
    // Đảm bảo channel có sound
    await _ensureAlarmChannelWithSound(soundRawName: soundRawName);

    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true, // mở fullscreen (OS quyết định)
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundRawName),
      enableVibration: true,
      visibility: NotificationVisibility.public,
      ticker: 'Alarm',
    );

    final details = NotificationDetails(android: androidDetails);

    // 👉 ADD: immediate test
    await _plugin.show(
      777,
      'Test notification',
      'Channel sound check',
      details,
    );

    // Dùng zonedSchedule để hẹn giờ chính xác theo local timezone
    final tzTime = tz.TZDateTime.from(dateTimeLocal, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Báo thức', // title
      'Đến giờ rồi!', // body
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
    debugPrint('[AlarmService] scheduled id=$id at $tzTime payload=$payload');
  }

  /// Huỷ 1 báo thức theo id
  static Future<void> cancel(int id) => _plugin.cancel(id);

  /// Huỷ tất cả báo thức
  static Future<void> cancelAll() => _plugin.cancelAll();

  // -------------------------------
  // Internal helpers
  // -------------------------------

  /// Callback khi người dùng TÁC ĐỘNG notification (khi app đang foreground/background).
  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('onNotificationTap payload=${response.payload}');
    _routeToAlarmRing(response.payload);
  }

  /// Nếu app được LAUNCH do notification → tự điều hướng tới /alarm_ring
  static Future<void> _maybeAutoRouteFromLaunch() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final payload = details!.notificationResponse?.payload;
      // Chờ frame đầu để chắc chắn navigatorKey sẵn sàng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _routeToAlarmRing(payload);
      });
    }
  }

  /// Điều hướng về /alarm_ring + truyền payload (nếu có)
  static void _routeToAlarmRing(String? payload) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    // Đưa người dùng vào app (nếu đang ở màn nào khác)
    // Tùy luồng bạn có thể bỏ dòng dưới nếu không cần về Home
    if (nav.canPop()) {
      // giữ nguyên stack, chỉ push lên
    } else {
      nav.pushNamedAndRemoveUntil('/home', (r) => false);
    }

    nav.pushNamed('/alarm_ring', arguments: payload);
  }

  /// Đảm bảo tồn tại kênh thông báo có âm thanh raw
  static Future<void> _ensureAlarmChannelWithSound({
    required String soundRawName,
  }) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return;

    final channel = AndroidNotificationChannel(
      _alarmChannelId,
      _alarmChannelName,
      description: _alarmChannelDesc,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundRawName),
    );

    await android.createNotificationChannel(channel);
  }
}
