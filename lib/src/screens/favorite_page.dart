import 'package:flutter/material.dart';
import '../Utils/event_repository.dart';
import '../Models/event_model.dart';
// import file FavoriteHelper Anda di sini
// import '...' 
import '../Utils/app_colors.dart'; 

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // ✅ KOREKSI 1: Inisialisasi Singleton yang benar
  final EventRepository _eventRepo = EventRepository.instance; 
  
  // Asumsi: Instance FavoriteHelper Anda
  // final FavoriteHelper _favHelper = FavoriteHelper.instance; 
  
  // State untuk menyimpan ID yang difavoritkan
  List<String> _favoriteIds = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteIds();
  }
  
  // Asumsi: Fungsi untuk memuat ID favorit dari SharedPreferences/Storage
  void _loadFavoriteIds() {
    // ⚠️ Ganti dengan logika asinkron yang benar dari helper Anda
    // Contoh:
    // List<String> ids = await _favHelper.getFavoriteIds();
    // setState(() { _favoriteIds = ids; });
    
    // Karena ini hanya contoh, kita akan mock data atau membiarkan kode utama di StreamBuilder.
    // Jika FavoriteHelper().getFavoriteIds() mengembalikan Future, Anda harus menggunakan FutureBuilder di atas ini.
    // Untuk menyederhanakan, kita akan asumsikan FavoriteHelper memberikan List<String> sync.
    
    // Contoh sederhana (ganti dengan helper Anda yang sebenarnya):
    setState(() {
      _favoriteIds = ['id_event_1', 'id_event_2']; // GANTI DENGAN LOGIKA ASLI ANDA
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_favoriteIds.isEmpty) {
        // Tampilkan loading/placeholder jika ID belum dimuat
        return const Center(child: Text("Memuat daftar favorit...")); 
    }
    
    // ✅ KOREKSI 2: Menggunakan StreamBuilder untuk mendengarkan Stream
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Favorit Anda"),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: StreamBuilder<List<EventModel>>(
        // 🎯 Input Stream: Panggil method repo yang mengembalikan Stream
        stream: _eventRepo.getEventsByIds(_favoriteIds), 
        
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error memuat event: ${snapshot.error}"),
            );
          }
          
          final List<EventModel> favoriteEvents = snapshot.data ?? [];

          if (favoriteEvents.isEmpty) {
            return const Center(
              child: Text("Anda belum memiliki event favorit."),
            );
          }

          // Tampilkan daftar event yang difavoritkan
          return ListView.builder(
            itemCount: favoriteEvents.length,
            itemBuilder: (context, index) {
              final EventModel event = favoriteEvents[index];
              return ListTile(
                leading: const Icon(Icons.favorite, color: AppColors.error),
                title: Text(event.title),
                subtitle: Text(event.location),
                // TODO: Tambahkan navigasi ke DetailPage
              );
            },
          );
        },
      ),
    );
  }
}