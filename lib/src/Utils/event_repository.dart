import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../Models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final String _eventsCollection = 'events';
  final String _registrationsCollection = 'registrations';

  // ===============================================
  // 1. SINGLETON SETUP
  // ===============================================
  static final EventRepository _instance = EventRepository._internal();
  
  EventRepository._internal();

  // Getter Statis yang dipanggil di file lain (Contoh: EventRepository.instance)
  static EventRepository get instance => _instance; 
  // ===============================================

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  final CollectionReference _events = FirebaseFirestore.instance.collection('events');
  final CollectionReference _registrations = FirebaseFirestore.instance.collection('registrations');


  // ===============================================
  // II. CRUD EVENTS & DATA STREAMING
  // ===============================================

  // 1. Tambah Event Baru
  Future<void> addEvent(EventModel event) async {
    try {
      final eventMap = event.toJson();
      // Tambahkan timestamp saat event dibuat (Berguna untuk pengurutan)
      eventMap['timestamp'] = FieldValue.serverTimestamp(); 
      await _events.add(eventMap);
    } catch (e) {
      throw Exception("Gagal mempublikasikan event: ${e.toString()}");
    }
  }

  // 2. Stream Semua Events (untuk HomePage)
  Stream<List<EventModel>> getEventsStream() {
    return _events
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  // 3. Stream Events Berdasarkan Daftar ID (untuk FavoritePage dan NotificationPage)
  Stream<List<EventModel>> getEventsByIds(List<String> eventIds) {
    if (eventIds.isEmpty) return Stream.value([]);
    
    // Batasan Firestore: whereIn hanya mendukung maksimum 10 ID.
    if (eventIds.length > 10) {
        eventIds = eventIds.sublist(0, 10);
    }

    return _events
        .where(FieldPath.documentId, whereIn: eventIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  // 4. Stream Events yang Diupload Pengguna Saat Ini (untuk ProfilePage)
  // ✅ METHOD YANG MENGATASI ERROR UNDEFINED
  Stream<List<EventModel>> getUserUploadedEventsStream(String userId) {
      return _events
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return EventModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
  }

  // 5. Delete Event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _events.doc(eventId).delete();
    } catch (e) {
      throw Exception("Gagal menghapus event: ${e.toString()}");
    }
  }


  // ===============================================
  // III. GOOGLE MAPS FUNCTIONS CALLS
  // ===============================================
  
  // 6. Mencari Lokasi (Autocomplete)
  Future<List<dynamic>> searchPlaces(String query) async {
    try {
      final result = await _functions.httpsCallable('searchPlaces').call({'query': query});
      return result.data ?? []; 
    } on FirebaseFunctionsException {
      throw Exception("Gagal memuat saran lokasi dari backend.");
    } catch (e) {
      throw Exception("Gagal terhubung ke Cloud Functions.");
    }
  }

  // 7. Mengambil Detail Lokasi (Coordinates)
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final result = await _functions.httpsCallable('getPlaceDetails').call({'placeId': placeId});
      return result.data; 
    } on FirebaseFunctionsException {
      throw Exception("Gagal mengambil detail koordinat dari backend.");
    } catch (e) {
      throw Exception("Gagal terhubung ke Cloud Functions.");
    }
  }

  // ===============================================
  // IV. REGISTRATION & TICKET
  // ===============================================

  // 8. Cek Status Pendaftaran
  Future<bool> checkRegistrationStatus(String eventId) async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    final snapshot = await _registrations
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
        
    return snapshot.docs.isNotEmpty;
  }

  // 9. Mendaftar Event
  Future<void> registerEvent(EventModel event) async {
    final userId = currentUserId;
    if (userId == null) throw Exception("User not logged in.");
    
    final isRegistered = await checkRegistrationStatus(event.id);
    if (isRegistered) return; 

    try {
      Map<String, dynamic> registrationData = {
        'userId': userId,
        'eventId': event.id, 
        'eventTitle': event.title,
        'eventLocation': event.location, 
        'registrationDate': FieldValue.serverTimestamp(),
        'status': 'registered',
      };
      
      await _registrations.add(registrationData);
    } catch (e) {
      throw Exception("Pendaftaran gagal: ${e.toString()}");
    }
  }

  // 10. Batalkan Pendaftaran
  Future<void> cancelRegistration(String eventId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception("User not logged in.");

    try {
      final querySnapshot = await _registrations
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
      }
    } catch (e) {
      throw Exception("Pembatalan pendaftaran gagal: ${e.toString()}");
    }
  }
}