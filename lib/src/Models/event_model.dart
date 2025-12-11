import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String date;
  final String location;
  final String description;
  final String imagePath;
  final String userId;
  final String? registrationLink;
  final Timestamp? timestamp; 
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
    this.timestamp,
    this.eventLat,
    this.eventLng,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'location': location,
      'description': description,
      'imagePath': imagePath,
      'userId': userId,
      'registrationLink': registrationLink,
      'timestamp': FieldValue.serverTimestamp(), 
      'eventLat': eventLat,
      'eventLng': eventLng,
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
      registrationLink: map['registrationLink'] as String?,
      timestamp: map['timestamp'] as Timestamp?,
      eventLat: map['eventLat'] as double?,
      eventLng: map['eventLng'] as double?,
    );
  }
}