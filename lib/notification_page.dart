import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_model.dart'; // Membutuhkan EventModel

// Pastikan file 'event_model.dart' ada dan memiliki kelas EventModel
// dan fungsi EventModel.fromMap.

class AppColors {
  static const primary = Color.fromRGBO(232, 0, 168, 1);
  static const background = Color(0xFFF5F5F5);
  static const textDark = Colors.black87;
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // State untuk pengaturan toggle notifikasi
  bool _isNotificationEnabled = true;

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