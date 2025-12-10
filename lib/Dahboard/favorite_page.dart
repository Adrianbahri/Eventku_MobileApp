import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Fungsi/favorite_helper.dart'; 
import '../Fungsi/app_colors.dart'; 
import '../Fungsi/event_model.dart'; // <<< Import EventModel
import 'detail_page.dart'; // <<< Import DetailPage

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
    loadFavorites();
  }

  // FUNGSI: Memuat ID Favorit dan Data Event terkait dari Firestore
  Future<void> loadFavorites() async {
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
          return EventModel.fromMap(doc.data(), doc.id);
        }).toList();
        
      } catch (e) {
        // Handle error jika koneksi/data bermasalah
        print("Error memuat event favorit: $e");
      }
    }

    setState(() {
      favoriteEvents = loadedEvents;
      isLoading = false;
    });
  }

  // FUNGSI: Menghapus Favorit dan Memuat Ulang Daftar
  void _removeFavorite(String eventId) async {
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

  // WIDGET BARU: Item Daftar Event Favorit (Mirip TicketPage)
  Widget _buildFavoriteItem(BuildContext context, EventModel event) {
    return GestureDetector(
      onTap: () {
        // Aksi Klik: Navigasi ke DetailPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(event: event),
          ),
        ).then((_) {
          // Muat ulang favorit saat kembali dari DetailPage, 
          // untuk berjaga-jaga jika status favorit diubah di sana.
          loadFavorites();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        decoration: BoxDecoration(
          color: AppColors.textLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul & Tanggal
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
              
              // Pembatas (Opsional, mirip TicketPage)
              CustomPaint(
                painter: DashedBorderPainter(),
                child: const SizedBox(height: 1),
              ),
              
              const SizedBox(height: 10),

              // ID dan Tombol Hapus Favorit (Ganti QR Code)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID Event:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text(event.id.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  // Tombol Hapus Favorit
                  IconButton(
                    icon: const Icon(Icons.favorite, size: 36, color: Colors.red),
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
      appBar: AppBar(
        title: const Text("Favorit Saya"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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

// Custom Painter untuk Garis Putus-putus (Dashed Border) - Dikutip dari TicketPage
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