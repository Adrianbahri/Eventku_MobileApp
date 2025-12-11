import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint
import '../Models/event_model.dart';
import '../Utils/app_colors.dart';
import '../Utils/notification_service.dart'; // Mengandung NotificationService & NotificationPrefs
import '../Utils/event_repository.dart'; // Mengandung EventRepository

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // State untuk pengaturan toggle notifikasi
  bool _isNotificationEnabled = true;
  // State untuk jam pengingat kustom (0.5 = 30 menit, 1.0 = 1 jam)
  double _reminderHours = 1.0; 
  
  // ✅ Instance Repository (menggunakan getter statis yang aman)
  final EventRepository _eventRepo = EventRepository.instance;

  @override
  void initState() {
    super.initState();
    NotificationService().initNotification();
    _loadPreferences(); 
  }
  
  // FUNGSI UNTUK MUAT PREFERENSI
  Future<void> _loadPreferences() async {
    final hours = await NotificationPrefs.getReminderHours();
    setState(() {
      _reminderHours = hours;
      // Note: Di sini Anda juga bisa memuat status _isNotificationEnabled jika disimpan
    });
  }


  // 📝 Logika Inti: Menghitung dan Menjadwalkan Pengingat Lokal
  void _scheduleNotificationsForEvent(EventModel event) {
    if (!_isNotificationEnabled) {
      NotificationService().cancelEventNotifications(event.id.hashCode);
      return; 
    }

    final DateTime eventDateTime;
    try {
      // Asumsi format data Firestore dari AddEventPage: "DD/MM/YYYY HH:MM"
      eventDateTime = DateFormat("dd/MM/yyyy HH:mm").parse(event.date); 
    } catch (e) {
      debugPrint("Error parsing event date string for event ${event.id}: ${event.date}. Error: $e");
      return; 
    }
    
    final DateTime now = DateTime.now();
    if (eventDateTime.isBefore(now)) return;

    int idBase = event.id.hashCode;

    // -----------------------------------------------------------
    // 1. JADWAL H-1 HARI (Pengingat statis)
    // -----------------------------------------------------------
    DateTime scheduledDayBefore = eventDateTime.subtract(const Duration(days: 1));
    
    if (scheduledDayBefore.isAfter(now)) {
      NotificationService().scheduleEventNotification(
        id: idBase + 1, // ID unik
        title: "Pengingat Event: ${event.title}",
        body: "Event akan dimulai besok di ${event.location}. Persiapkan diri Anda!",
        scheduledTime: scheduledDayBefore,
      );
    }

    // -----------------------------------------------------------
    // 2. JADWAL KUSTOM (H-X Jam/Menit)
    // -----------------------------------------------------------
    int minutesToSubtract = (_reminderHours * 60).round(); 
    DateTime scheduledCustomTime = eventDateTime.subtract(Duration(minutes: minutesToSubtract));
    
    String timeLabel = minutesToSubtract < 60 
        ? '$minutesToSubtract menit' 
        : '${_reminderHours.toStringAsFixed(1).replaceAll('.0', '')} jam';

    if (scheduledCustomTime.isAfter(now)) {
      NotificationService().scheduleEventNotification(
        id: idBase + 2, // ID unik untuk pengingat kustom
        title: "${event.title}",
        body: "Event akan dimulai dalam $timeLabel lagi!",
        scheduledTime: scheduledCustomTime,
      );
      debugPrint("Custom Reminder Scheduled: $timeLabel before event time.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Notifikasi & Pengingat Event",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. SETTING TOGGLE & CUSTOM REMINDER
          _buildNotificationSetting(),
          
          const SizedBox(height: 30),
          
          // 2. JUDUL INBOX
          const Text(
            "Event Terdaftar (Laci Pengingat Anda)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 15),

          // 3. LIST INBOX DARI FIREBASE
          _buildEventInboxList(),
        ],
      ),
    );
  }

  // ✅ WIDGET PENGATURAN NOTIFIKASI KUSTOM
  Widget _buildNotificationSetting() {
    // Opsi yang tersedia (Jam dan Menit)
    final List<Map<String, dynamic>> options = [
      {'label': '30 Menit Sebelumnya', 'value': 0.5},
      {'label': '1 Jam Sebelumnya', 'value': 1.0},
      {'label': '2 Jam Sebelumnya', 'value': 2.0},
      {'label': '6 Jam Sebelumnya', 'value': 6.0},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Notifikasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Izinkan Pengingat Event",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              Switch(
                value: _isNotificationEnabled,
                onChanged: (value) {
                  setState(() {
                    _isNotificationEnabled = value;
                  });
                  if (!value) {
                    NotificationService().cancelAllNotifications();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(value ? "Notifikasi diaktifkan." : "Notifikasi dinonaktifkan.")),
                  );
                },
                activeTrackColor: AppColors.primary.withOpacity(0.5),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // 🎯 DROPDOWN PENGATURAN WAKTU
          const Text(
            "Ingatkan Saya (Sebelum Event)",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: _reminderHours,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                style: const TextStyle(color: AppColors.textDark, fontSize: 16),
                items: options.map((option) {
                  return DropdownMenuItem<double>(
                    value: option['value'],
                    child: Text(option['label'] as String),
                  );
                }).toList(),
                onChanged: (double? newValue) async {
                  if (newValue != null) {
                    // Simpan preferensi baru
                    await NotificationPrefs.saveReminderHours(newValue);
                    setState(() {
                      _reminderHours = newValue;
                    });
                    // Refresh StreamBuilder untuk menjadwalkan ulang notifikasi dengan waktu baru
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pengingat diatur ulang.')),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FUNGSI LIST EVENT TERDAFTAR
  Widget _buildEventInboxList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(
        child: Text("Anda harus login untuk melihat event yang terdaftar."),
      );
    }

    // 1. STREAM REGISTRATIONS: Ambil semua dokumen pendaftaran milik user ini
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      
      builder: (context, registrationSnapshot) {
        if (registrationSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (registrationSnapshot.hasError) {
          return Center(child: Text("Error memuat pendaftaran: ${registrationSnapshot.error}"));
        }

        // Ekstrak semua eventId yang didaftarkan
        final List<String> registeredEventIds = registrationSnapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .map((data) => data['eventId'] as String)
            .toList();

        // 2. STREAM EVENTS: Gunakan ID yang didapat untuk mengambil data EventModel lengkap
        if (registeredEventIds.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text("Anda belum mendaftar ke event manapun."),
            ),
          );
        }
        
        return StreamBuilder<List<EventModel>>(
          stream: _eventRepo.getEventsByIds(registeredEventIds),
          
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (eventSnapshot.hasError) {
              return Center(child: Text("Error memuat event: ${eventSnapshot.error}"));
            }

            final List<EventModel> registeredEvents = eventSnapshot.data ?? [];
            
            // 💡 PENJADWALAN NOTIFIKASI
            // Panggil _scheduleNotificationsForEvent di sini untuk setiap event
            if (_isNotificationEnabled) {
              for (var event in registeredEvents) {
                _scheduleNotificationsForEvent(event);
              }
            } else {
              for (var event in registeredEvents) {
                 NotificationService().cancelEventNotifications(event.id.hashCode);
              }
            }


            // Tampilkan daftar event yang sudah didaftar
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: registeredEvents.length,
              itemBuilder: (context, index) {
                final EventModel event = registeredEvents[index];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.alarm_on, color: AppColors.primary),
                      title: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                      ),
                      subtitle: Text(
                        "Pengingat Aktif: ${event.date}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      trailing: const Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
                      onTap: () {
                        // TODO: Navigasi ke DetailPage event ini
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Pengingat untuk: ${event.title}")),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}