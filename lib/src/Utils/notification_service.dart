import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  /// Menginisialisasi service notifikasi dan meminta izin Exact Alarm.
  Future<void> initNotification() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    // 🔑 PERBAIKAN: Meminta Izin Exact Alarm untuk Android 12+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
  }

  /// 📝 Fungsi untuk menjadwalkan notifikasi pada waktu tertentu
  Future<void> scheduleEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Memastikan waktu yang dijadwalkan masih di masa depan
    if (scheduledTime.isBefore(DateTime.now())) return;

    // 📝 Detail Notifikasi Android
    final NotificationDetails notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_channel_id',
          'Event Reminders',
          channelDescription: 'Notifikasi untuk pengingat event',
          importance: Importance.max,
          priority: Priority.high,
        ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      // Konversi DateTime ke TZDateTime
      tz.TZDateTime.from(scheduledTime, tz.local), 
      notificationDetails,
      // Menggunakan Exact Alarms
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
    );
  }
  
  /// Membatalkan notifikasi tunggal.
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Membatalkan semua notifikasi.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}