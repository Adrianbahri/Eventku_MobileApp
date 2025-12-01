import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// PASTIKAN PATH INI BENAR DI PROYEK ANDA
import 'event_model.dart'; 
import 'detail_page.dart'; 

// --- 1. KONSTANTA WARNA ---
class AppColors {
 static const primary = Color.fromRGBO(232, 0, 168, 1);
 static const background = Color(0xFFF5F5F5);
 static const textDark = Colors.black87;
}

// --- 2. HALAMAN UTAMA PROFIL ---
class ProfilePage extends StatelessWidget {
 const ProfilePage({super.key});

 @override
 Widget build(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  final userName = user?.displayName?.split(' ').first ?? 'User';
  final currentUserId = user?.uid;

  if (user == null || currentUserId == null) {
   // Menangani jika pengguna belum login (Error State)
   return Scaffold(
     appBar: AppBar(
      title: const Text("Profil", style: TextStyle(color: AppColors.textDark)),
      backgroundColor: AppColors.background,
     ),
     body: const Center(child: Text("Anda harus login untuk melihat profil."))
   );
  }

  return Scaffold(
   appBar: AppBar(
    // Mengganti 'Profil Saya' menjadi 'Back' jika ada tombol kembali
    title: const Text(
     "Profil Saya", 
     style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)
    ),
    backgroundColor: AppColors.background,
    elevation: 0,
    iconTheme: const IconThemeData(color: AppColors.textDark), // Warna ikon back
   ),
   backgroundColor: AppColors.background,
   body: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0), // Padding diseragamkan
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      // --- HEADER NAMA PENGGUNA ---
      Text(
       "Halo, $userName",
       style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
      Text(
       user.email ?? 'Email tidak tersedia',
       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      const SizedBox(height: 30),

      const Text(
       "Event yang Anda Upload",
       style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      const SizedBox(height: 15),

      // --- LIST EVENT PRIBADI ---
      _UserEventList(currentUserId: currentUserId),
      
      const SizedBox(height: 40),

      // --- OPSI LOGOUT ---
      const _LogoutButton(),
     ],
    ),
   ),
  );
 }
}

// ------------------------------------------
// --- WIDGET LIST EVENT PENGGUNA ---
// ------------------------------------------

class _UserEventList extends StatelessWidget {
 final String currentUserId;
 const _UserEventList({required this.currentUserId});

 // Menampilkan dialog konfirmasi sebelum menghapus
 Future<bool> _showDeleteConfirmationDialog(BuildContext context, String title) async {
  return await showDialog<bool>(
   context: context,
   builder: (context) => AlertDialog(
    title: const Text('Hapus Event'),
    content: Text('Apakah Anda yakin ingin menghapus event "$title"?'),
    actions: [
     TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: const Text('Batal'),
     ),
     TextButton(
      onPressed: () => Navigator.of(context).pop(true),
      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
     ),
    ],
   ),
  ) ?? false; // Nilai default false jika dialog ditutup
 }

 // Fungsi untuk menghapus event dari Firestore
 Future<void> _deleteEvent(BuildContext context, String eventId, String eventTitle) async {
  final shouldDelete = await _showDeleteConfirmationDialog(context, eventTitle);

  if (!shouldDelete) return; // Batal jika pengguna memilih Batal

  try {
   // Hapus dokumen dari Firestore
   await FirebaseFirestore.instance.collection('events').doc(eventId).delete();

   // TODO: Jika menggunakan Firebase Storage, tambahkan logika untuk menghapus gambar di sini

   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Event berhasil dihapus.'), backgroundColor: Colors.green),
   );
  } catch (e) {
   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Gagal menghapus event: $e'), backgroundColor: Colors.red),
   );
  }
 }

 @override
 Widget build(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
   // Kueri yang sudah benar: filter berdasarkan userId DAN order berdasarkan timestamp
   stream: FirebaseFirestore.instance
     .collection('events')
     .where('userId', isEqualTo: currentUserId) 
     .orderBy('timestamp', descending: true)
     .snapshots(),
   builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
     return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (snapshot.hasError) {
     // Jika errornya adalah 'failed-precondition' (Indeks hilang), arahkan pengguna
     if (snapshot.error.toString().contains('failed-precondition')) {
      return const Text(
       "Error Firestore: Kueri memerlukan indeks gabungan. Silakan buat di Firebase Console.",
       style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
      );
     }
     return Center(child: Text("Error: ${snapshot.error}"));
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
     return const Center(child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Anda belum mengupload event apa pun."),
     ));
    }

    final List<EventModel> userEvents = snapshot.data!.docs.map((doc) {
     return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();

    return ListView.builder(
     shrinkWrap: true, 
     physics: const NeverScrollableScrollPhysics(),
     itemCount: userEvents.length,
     itemBuilder: (context, index) {
      final event = userEvents[index];
      
      // Pastikan imagePath adalah URL jaringan yang valid
      final isNetworkImageValid = event.imagePath.startsWith('http');

      return Card(
       margin: const EdgeInsets.symmetric(vertical: 8),
       elevation: 2,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       child: ListTile(
        leading: ClipRRect(
         borderRadius: BorderRadius.circular(8),
         child: isNetworkImageValid && event.imagePath.isNotEmpty
           ? Image.network(
             event.imagePath, 
             width: 50, height: 50, 
             fit: BoxFit.cover,
             errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.broken_image, color: Colors.grey, size: 24),
            )
           : const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${event.date} - ${event.location}"),
        trailing: IconButton(
         icon: const Icon(Icons.delete, color: Colors.red),
         // Opsi Hapus Event DENGAN KONFIRMASI
         onPressed: () => _deleteEvent(context, event.id, event.title), 
        ),
        onTap: () {
         // Navigasi ke DetailPage
         Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(event: event)));
        },
       ),
      );
     },
    );
   },
  );
 }
}

// --- 4. WIDGET TOMBOL LOGOUT ---
class _LogoutButton extends StatelessWidget {
 const _LogoutButton(); // Menjadikan const

 @override
 Widget build(BuildContext context) {
  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 10.0),
   child: SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
     icon: const Icon(Icons.logout),
     label: const Text("Log Out"),
     style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
     ),
     onPressed: () async {
      // Logika Sign Out
      await FirebaseAuth.instance.signOut();
      
      // Navigasi ke halaman '/login' dan hapus semua rute sebelumnya
      if (context.mounted) {
       // ASUMSI: Rute '/login' didefinisikan di MaterialApp Anda
       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
     },
    ),
   ),
  );
 }
}