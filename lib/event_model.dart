import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String date;
  final String location;
  final String description;
  final String imagePath;
  final String userId; // <--- FIELD BARU

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.userId,
  });

  // Metode wajib untuk mengirim data ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'location': location,
      'description': description,
      'imagePath': imagePath,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      id: documentId,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      userId: map['userId'] ?? '',
    );
  }
}
