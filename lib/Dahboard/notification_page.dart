import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 💡 IMPORT BARU: Diperlukan untuk parsing string tanggal/waktu
import '../Fungsi/event_model.dart'; // Membutuhkan EventModel
import '../Fungsi/app_colors.dart';
import '../Fungsi/notification_service.dart'; // Import service notifikasi

// Pastikan file 'event_model.dart' ada dan memiliki kelas EventModel
// dan fungsi EventModel.fromMap.

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // State untuk pengaturan toggle notifikasi
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    // 💡 INIT: Inisialisasi service notifikasi saat state dibuat
    NotificationService().initNotification();
  }

  // 📝 Logika Inti: Menghitung dan Menjadwalkan Pengingat
  void _scheduleNotificationsForEvent(EventModel event) {
    // Jika notifikasi dinonaktifkan, hentikan proses penjadwalan
    if (!_isNotificationEnabled) return;

    // 1. 🔑 PERBAIKAN: Parsing String 'date' menjadi DateTime
    final DateTime eventDateTime;
    try {
      // Data event.date Anda adalah: "DD/MM/YYYY HH:MM" (misalnya "10/12/2025 02:44")
      // Gunakan DateFormat untuk mengkonversi string ini ke objek DateTime.
      eventDateTime = DateFormat("dd/MM/yyyy HH:mm").parse(event.date); 
    } catch (e) {
      debugPrint("Error parsing event date string for event ${event.id}: ${event.date}. Error: $e");
      return; // Lewati jika format tanggal tidak valid
    }
    
    final DateTime now = DateTime.now();

    // Jika event sudah berlalu (menggunakan waktu yang benar), jangan dijadwalkan
    if (eventDateTime.isBefore(now)) return;

    // ID Base Notifikasi: Menggunakan hashcode dari ID event agar setiap event unik
    int idBase = event.id.hashCode;

    // 1. Jadwal H-1 Hari
    DateTime scheduledDayBefore = eventDateTime.subtract(const Duration(days: 1));
    
    // Hanya jadwalkan jika waktu mundur (H-1 Hari) masih di masa depan
    if (scheduledDayBefore.isAfter(now)) {
      NotificationService().scheduleEventNotification(
        id: idBase + 1, // ID unik untuk pengingat H-1 Hari
        title: "Pengingat Event: ${event.title}",
        body: "Event akan dimulai besok di ${event.location}. Persiapkan diri Anda!",
        scheduledTime: scheduledDayBefore,
      );
    }

    // 2. Jadwal H-1 Jam
    DateTime scheduledHourBefore = eventDateTime.subtract(const Duration(hours: 1));
    
    // Hanya jadwalkan jika waktu mundur (H-1 Jam) masih di masa depan
    if (scheduledHourBefore.isAfter(now)) {
      NotificationService().scheduleEventNotification(
        id: idBase + 2, // ID unik untuk pengingat H-1 Jam
        title: "Segera Dimulai: ${event.title}",
        body: "Event akan dimulai dalam 1 jam lagi.",
        scheduledTime: scheduledHourBefore,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Notifikasi & Event Inbox",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. SETTING TOGGLE NOTIFIKASI
          _buildNotificationSetting(),
          
          const SizedBox(height: 30),
          
          // 2. JUDUL INBOX
          const Text(
            "Event Terbaru (Inbox Semua Pengguna)",
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

  Widget _buildNotificationSetting() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              "Izinkan Notifikasi (Push Notification)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Switch(
            value: _isNotificationEnabled,
            onChanged: (value) {
              setState(() {
                _isNotificationEnabled = value;
              });
              
              // 💡 AKSI: Jika notifikasi dimatikan, batalkan semua notifikasi pending
              if (!value) {
                NotificationService().flutterLocalNotificationsPlugin.cancelAll();
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? "Notifikasi diaktifkan." : "Notifikasi dinonaktifkan."),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            activeTrackColor: AppColors.primary.withOpacity(0.5),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ✅ FUNGSI BARU: Mengambil data event dari Firestore
  Widget _buildEventInboxList() {
    return StreamBuilder<QuerySnapshot>(
      // Ambil semua event, diurutkan berdasarkan timestamp terbaru
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('timestamp', descending: true) 
          .snapshots(),
      
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error memuat event: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                "Belum ada event yang ditambahkan.",
                style: TextStyle(color: AppColors.textDark),
              ),
            ),
          );
        }

        // Konversi data ke List<EventModel>
        final List<EventModel> events = snapshot.data!.docs.map((doc) {
          return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        
        // 💡 PENJADWALAN NOTIFIKASI
        // Jalankan logika penjadwalan untuk setiap event yang dimuat jika notif aktif
        if (_isNotificationEnabled) {
          for (var event in events) {
            _scheduleNotificationsForEvent(event);
          }
        }

        // Tampilkan daftar event
        return ListView.builder(
          shrinkWrap: true, // Penting karena berada di dalam ListView parent
          physics: const NeverScrollableScrollPhysics(), // Nonaktifkan scroll
          itemCount: events.length,
          itemBuilder: (context, index) {
            final EventModel event = events[index];
            
            // Cek apakah event ini diunggah oleh pengguna saat ini
            final bool isMyEvent = event.userId == FirebaseAuth.instance.currentUser?.uid;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  // Event yang baru di-add (asumsi belum 1 hari) bisa dianggap "belum dibaca"
                  color: index < 3 ? AppColors.primary.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "${event.location} - ${event.date}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMyEvent ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isMyEvent ? "Event Saya" : "Baru",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isMyEvent ? Colors.blue : Colors.green,
                      ),
                    ),
                  ),
                  onTap: () {
                    // TODO: Navigasi ke DetailPage event ini
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lihat detail event: ${event.title}")),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}