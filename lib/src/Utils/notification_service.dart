import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart'; 

// -------------------------------------------------------------
// HELPER: Menyimpan dan Mengambil Preferensi Jam Pengingat
// -------------------------------------------------------------
class NotificationPrefs {
  static const String _keyReminderHours = 'reminder_hours';

  // Menyimpan preferensi jam (misalnya, 1.0 = 1 jam, 0.5 = 30 menit)
  static Future<void> saveReminderHours(double hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyReminderHours, hours);
  }

  // Mengambil preferensi jam. Default adalah 1 jam (jika belum pernah disimpan)
  static Future<double> getReminderHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyReminderHours) ?? 1.0; 
  }
}
// -------------------------------------------------------------


class NotificationService {
  // 1. SETUP SINGLETON
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
    
    // Meminta Izin Exact Alarm untuk Android 12+ (Wajib untuk penjadwalan akurat)
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

  /// 📝 Fungsi untuk menjadwalkan notifikasi pada waktu tertentu (SATU KALI)
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
      
      // ✅ KOREKSI: Parameter yang menyebabkan error 'Undefined name' dihapus.
      // Notifikasi akan dipicu sekali pada waktu absolut.
    );
  }
  
  /// Membatalkan notifikasi tunggal.
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Membatalkan Notifikasi Terkait Event Berdasarkan HashCode ID
  void cancelEventNotifications(int eventHashCode) {
    // ID notifikasi dijadwalkan dengan pola:
    // H-1 Hari = eventHashCode + 1
    // H-X Jam/Menit = eventHashCode + 2 (untuk pengingat kustom)

    flutterLocalNotificationsPlugin.cancel(eventHashCode + 1);
    flutterLocalNotificationsPlugin.cancel(eventHashCode + 2);
    
    debugPrint('Cancelled scheduled notifications for event hash: $eventHashCode');
  }

  /// Membatalkan semua notifikasi.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}