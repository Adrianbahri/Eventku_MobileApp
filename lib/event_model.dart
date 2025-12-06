import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String date;
  final String location;
  final String description;
  final String imagePath; // Berisi URL Gambar dari Firebase Storage
  final String userId;
  final Timestamp? timestamp; // Digunakan untuk sorting, diisi oleh Firestore

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.userId,
    this.timestamp,
  });

  // 🛠️ Metode untuk Mengirim Data ke Firestore (Digunakan untuk data baru)
  // Perhatikan: Kita TIDAK memasukkan 'id' di sini karena itu adalah ID Dokumen.
  // Field 'timestamp' akan ditambahkan secara terpisah saat memanggil .add()
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'location': location,
      'description': description,
      'imagePath': imagePath,
      'userId': userId,
      // Kita tidak perlu menyertakan nilai timestamp di toMap() ini.
      // Kita akan menambahkannya secara terpisah di AddEventPage agar Firestore
      // dapat mengisi FieldValue.serverTimestamp() dengan benar.
    };
  }

  // 🔎 Metode untuk Mengambil Data dari Firestore
  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      id: documentId,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      // Pastikan key 'imagePath' sudah benar
      imagePath: map['imagePath'] ?? '',
      userId: map['userId'] ?? '',
      // Ambil timestamp dari Firestore.
      timestamp: map['timestamp'] as Timestamp?,
    );
  }
}