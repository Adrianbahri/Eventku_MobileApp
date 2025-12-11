import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _eventsCollection = FirebaseFirestore.instance.collection('events');
  final CollectionReference _registrationsCollection = FirebaseFirestore.instance.collection('registrations');
  
  // Ambil ID pengguna saat ini. Akan bernilai null jika user logout.
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // --- 1. OPERASI READ (Membaca Data Event) ---

  // Mengambil SEMUA event sebagai Stream (untuk Dashboard)
  Stream<List<EventModel>> getEventsStream() {
    return _eventsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Mengambil event berdasarkan daftar ID (untuk Favorite)
  Future<List<EventModel>> getEventsByIds(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];
    
    // Batasan Firestore: whereIn hanya mendukung maksimum 10 ID per kueri.
    final List<String> batchIds = eventIds.sublist(0, eventIds.length > 10 ? 10 : eventIds.length); 

    final snapshot = await _eventsCollection
      .where(FieldPath.documentId, whereIn: batchIds)
      .get();
      
    return snapshot.docs.map((doc) {
      return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
  
  // Mengambil event yang diunggah oleh pengguna saat ini (untuk Profil)
  Stream<List<EventModel>> getUserUploadedEventsStream(String userId) {
    return _eventsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  // --- 2. OPERASI WRITE & DELETE EVENT ---

  // Menambah event baru (untuk AddEventPage)
  Future<void> addEvent(EventModel newEvent) async {
    // Tambahkan timestamp saat event dibuat (Berguna untuk pengurutan)
    final Map<String, dynamic> data = newEvent.toMap();
    data['timestamp'] = FieldValue.serverTimestamp(); 
    
    await _eventsCollection.add(data);
  }

  // Menghapus event (untuk ProfilePage)
  Future<void> deleteEvent(String eventId) async {
    // Note: Dalam aplikasi nyata, Anda juga perlu menghapus file poster dari Storage.
    await _eventsCollection.doc(eventId).delete();
  }
  
  // --- 3. OPERASI REGISTRASI (Tiket) ---
  
  // Mendaftar (Registrasi) event di Firestore
  Future<void> registerEvent(EventModel event) async {
      if (currentUserId == null) {
          throw Exception("User not logged in.");
      }
      
      Map<String, dynamic> registrationData = {
          'userId': currentUserId,
          'eventId': event.id, 
          'eventTitle': event.title,
          'eventLocation': event.location, 
          'registrationDate': FieldValue.serverTimestamp(),
          'status': 'registered',
      };

      await _registrationsCollection.add(registrationData);
  }

  // Membatalkan Pendaftaran (Hapus dari koleksi 'registrations')
  Future<void> cancelRegistration(String eventId) async {
      if (currentUserId == null) {
          throw Exception("User not logged in.");
      }
      
      final querySnapshot = await _registrationsCollection
          .where('userId', isEqualTo: currentUserId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.delete(); 
      }
  }

  // Cek Status Pendaftaran (untuk DetailPage)
  Future<bool> checkRegistrationStatus(String eventId) async {
      if (currentUserId == null) return false;
      
      final snapshot = await _registrationsCollection
          .where('userId', isEqualTo: currentUserId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
          
      return snapshot.docs.isNotEmpty;
  }
  
  // Mengambil Stream Tiket (untuk TicketPage)
  Stream<QuerySnapshot> getRegisteredTicketsStream(String userId) {
      return _registrationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('registrationDate', descending: true)
          .snapshots();
  }
}