import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Utils/favorite_helper.dart'; // Asumsi: FavoriteHelper berada di Utils
import '../Utils/app_colors.dart'; 
import '../Models/event_model.dart'; // Asumsi: EventModel berada di Models
import 'detail_page.dart'; // Asumsi: DetailPage berada di screens

// WIDGET UTAMA: Halaman Event Favorit - STATEFUL (Menggunakan Future Loading)
class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // Ubah tipe data untuk menyimpan model event lengkap
  List<EventModel> favoriteEvents = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Memuat favorit setelah widget selesai dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) => loadFavorites());
  }

  // FUNGSI: Memuat ID Favorit dan Data Event terkait dari Firestore
  Future<void> loadFavorites() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    final favoriteIds = await FavoriteHelper.getFavorites();
    List<EventModel> loadedEvents = [];

    if (favoriteIds.isNotEmpty) {
      try {
        // Ambil data event dari Firestore menggunakan daftar ID
        final snapshot = await FirebaseFirestore.instance
            .collection('events')
            .where(FieldPath.documentId, whereIn: favoriteIds)
            .get();

        loadedEvents = snapshot.docs.map((doc) {
          // ✅ KOREKSI MAPPER: Menggunakan fromJson
          return EventModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        
      } catch (e) {
        debugPrint("Error memuat event favorit: $e");
      }
    }

    if (mounted) {
      setState(() {
        favoriteEvents = loadedEvents;
        isLoading = false;
      });
    }
  }

  // FUNGSI: Menghapus Favorit dan Memuat Ulang Daftar
  void _removeFavorite(String eventId) async {
    if (!mounted) return;

    await FavoriteHelper.toggleFavorite(eventId);
    // Muat ulang daftar untuk refresh UI
    await loadFavorites(); 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Event dihapus dari Favorit.'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  // WIDGET BARU: Item Daftar Event Favorit (Diselaraskan dengan Desain Tiket)
  Widget _buildFavoriteItem(BuildContext context, EventModel event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(event: event),
          ),
        ).then((_) {
          if (mounted) {
            // Muat ulang setelah kembali untuk mencerminkan perubahan status favorit
            loadFavorites(); 
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        decoration: BoxDecoration(
          // PERBAIKAN: Background Putih bersih
          color: AppColors.textLight,
          // PERBAIKAN: Radius 15
          borderRadius: BorderRadius.circular(15), 
          // PERBAIKAN: Hapus Shadow
          boxShadow: const [], 
          // Tambahkan border tipis sebagai pemisah visual
          border: Border.all(color: Colors.grey.shade300, width: 1), // Ganti AppColors.secondary menjadi warna abu-abu
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul Event
              Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Detail Waktu/Lokasi
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(event.date, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(event.location, style: const TextStyle(color: Colors.grey, fontSize: 14), overflow: TextOverflow.ellipsis)),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Pembatas (Garis Dashed)
              CustomPaint(
                painter: DashedBorderPainter(),
                child: const SizedBox(height: 1, width: double.infinity), // Tambah width untuk mengisi
              ),
              
              const SizedBox(height: 10),

              // ID dan Tombol Hapus Favorit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID Event:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text(
                          event.id.substring(0, 8), 
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, 
                            color: AppColors.textDark
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol Hapus Favorit
                  IconButton(
                    // Menggunakan Ikon Hapus (Sampah)
                    icon: const Icon(Icons.delete_forever, size: 30, color: AppColors.error), 
                    onPressed: () => _removeFavorite(event.id), // Panggil fungsi hapus
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // PERBAIKAN: Latar Belakang Aplikasi Putih
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Favorit Saya", style: TextStyle(fontWeight: FontWeight.bold)),
          // PERBAIKAN: Header Putih
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark, // Teks Gelap
          elevation: 0.5,
        ),

        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : favoriteEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border,
                            size: 90, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          "Belum ada event favorit.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: favoriteEvents.length,
                    itemBuilder: (context, index) {
                      final event = favoriteEvents[index];
                      return _buildFavoriteItem(context, event);
                    },
                  ),
    );
  }
}

// Custom Painter untuk Garis Putus-putus (Dashed Border)
// Pastikan kode DashedBorderPainter ini ada di file yang sama atau diimpor
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 8, dashSpace = 4, startX = 0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}