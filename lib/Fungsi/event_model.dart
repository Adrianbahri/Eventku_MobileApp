import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String date;
  final String location;
  final String description;
  final String imagePath;
  final String userId;
  final String? registrationLink; // 🌟 PROPERTI BARU
  // Field opsional untuk sorting
  final Timestamp? timestamp; 

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.userId,
    this.registrationLink, // 🌟 Diperlukan di konstruktor
    this.timestamp, // Dibuat opsional karena bisa null saat membaca dari toMap()
  });

  // 🛠️ Metode untuk Mengirim Data ke Firestore (Create/Update)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'location': location,
      'description': description,
      'imagePath': imagePath,
      'userId': userId,
      'registrationLink': registrationLink, // 🌟 Tambahkan ke map
      // Gunakan serverTimestamp() untuk mencatat waktu yang akurat
      'timestamp': FieldValue.serverTimestamp(), 
    };
  }

  // 📥 Factory untuk Menerima Data dari Firestore (Read)
  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Pastikan casting aman dan berikan nilai default jika null
    return EventModel(
      id: documentId,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      userId: map['userId'] ?? '',
      registrationLink: map['registrationLink'] as String?, // 🌟 Ambil link
      // Ambil timestamp dari Firestore. Jika tidak ada, biarkan null.
      timestamp: map['timestamp'] as Timestamp?, 
    );
  }
}