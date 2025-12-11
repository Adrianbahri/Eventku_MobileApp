// File: lib/Utils/notification_service.dart
import 'package:flutter/foundation.dart';
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
    
    // Meminta Izin Exact Alarm untuk Android 12+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestExactAlarmsPermission();
      if (granted != true) {
         debugPrint("Exact Alarm permission not granted. Reminders might be inaccurate.");
      }
    }
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
      
      // 🔥 KOREKSI 1 & 2: HAPUS parameter yang usang (uiLocalNotificationDateInterpretation)
      // dan pastikan penggunaan enum yang benar (UILocalNotificationDateInterpretation.absoluteTime)
      // Note: UILocalNotificationDateInterpretation diubah namanya menjadi DarwinNotificationDetails di versi terbaru,
      // tetapi untuk meminimalisir error, kita akan menghapus parameter Android yang usang.
      
      // ✅ KOREKSI: Gunakan parameter yang benar untuk penjadwalan berulang/waktu tertentu
      matchDateTimeComponents: DateTimeComponents.time, 
    );
  }
  
  /// Membatalkan notifikasi tunggal (Digunakan untuk cleanup).
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Membatalkan Notifikasi Terkait Event Berdasarkan HashCode ID
  void cancelEventNotifications(int eventHashCode) {
    // ID notifikasi dijadwalkan dengan pola:
    // H-1 Hari = eventHashCode + 1
    // H-1 Jam = eventHashCode + 2

    // Batalkan notifikasi H-1 Hari
    flutterLocalNotificationsPlugin.cancel(eventHashCode + 1);
    
    // Batalkan notifikasi H-1 Jam
    flutterLocalNotificationsPlugin.cancel(eventHashCode + 2);
    
    debugPrint('Cancelled scheduled notifications for event hash: $eventHashCode');
  }

  /// Membatalkan semua notifikasi.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}