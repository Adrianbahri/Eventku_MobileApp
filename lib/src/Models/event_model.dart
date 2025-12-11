// File: lib/Models/event_model.dart

class EventModel {
  final String id;
  final String title;
  final String date;
  final String location;
  final String description;
  final String imagePath;
  final String userId;
  final String? registrationLink;
  final double? eventLat;
  final double? eventLng;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.userId,
    this.registrationLink,
    this.eventLat,
    this.eventLng,
  });

  // ------------------------------------------------------------------
  // ✅ FACTORY CONSTRUCTOR: Mengubah data Firestore menjadi objek Dart
  // ------------------------------------------------------------------
  // Menerima data Map (dari Firestore) dan ID dokumen.
  factory EventModel.fromJson(Map<String, dynamic> json, String id) {
    return EventModel(
      id: id, // ID diambil dari doc.id Firestore
      title: json['title'] as String,
      date: json['date'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String,
      userId: json['userId'] as String,
      
      // Penanganan nilai opsional/nullable
      registrationLink: json['registrationLink'] as String?,
      // Note: Firestore menyimpan angka sebagai num (number), konversi ke double
      eventLat: (json['eventLat'] as num?)?.toDouble(),
      eventLng: (json['eventLng'] as num?)?.toDouble(),
    );
  }

  // ------------------------------------------------------------------
  // 📝 MAPPER: Mengubah objek Dart menjadi Map (Untuk disimpan ke Firestore)
  // ------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      // Tidak perlu menyimpan ID di sini, Firestore akan membuatnya
      'title': title,
      'date': date,
      'location': location,
      'description': description,
      'imagePath': imagePath,
      'userId': userId,
      'registrationLink': registrationLink,
      'eventLat': eventLat,
      'eventLng': eventLng,
    };
  }
}