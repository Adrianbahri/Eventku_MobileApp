import 'package:flutter/material.dart';
import 'event_model.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // Opsional: untuk caching

// Pastikan AppColors bisa diakses
class AppColors {
 static const primary = Color.fromRGBO(232, 0, 168, 1);
 static const background = Color(0xFFF5F5F5);
 static const textDark = Colors.black87;
}

class DetailPage extends StatelessWidget {
 final EventModel event;
 const DetailPage({super.key, required this.event});

 // Widget untuk menampilkan gambar jaringan atau fallback
 Widget _buildEventImage(BuildContext context, double height) {
  final bool isNetworkImage = event.imagePath.startsWith('http');
  
  if (!isNetworkImage || event.imagePath.isEmpty) {
   // Fallback jika path bukan URL atau kosong
   return Container(
    height: height,
    color: Colors.grey[300],
    child: const Center(
     child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
    ),
   );
  }

  return Image.network(
   event.imagePath,
   fit: BoxFit.cover,
   height: height,
   errorBuilder: (context, error, stackTrace) {
    return Container(
     color: Colors.grey[300],
     child: const Center(
      child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
     ),
    );
   },
   loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
     height: height,
     color: Colors.grey[200],
     child: Center(
      child: CircularProgressIndicator(
       color: AppColors.primary,
       value: loadingProgress.expectedTotalBytes != null
         ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
         : null,
      ),
     ),
    );
   },
  );
 }

 @override
 Widget build(BuildContext context) {
  final double screenHeight = MediaQuery.of(context).size.height;
  final double imageContainerHeight = screenHeight * 0.65;
  final double infoContainerHeight = screenHeight * 0.45;

  return Scaffold(
   body: Stack(
    children: [
     // 1. GAMBAR POSTER (Menggunakan fungsi helper _buildEventImage)
     Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: imageContainerHeight, 
      child: Stack( // Gunakan Stack agar bisa menumpuk gambar dan gradient
       fit: StackFit.expand,
       children: [
        // Gambar Jaringan atau Fallback
        _buildEventImage(context, imageContainerHeight),

        // Gradient overlay agar tombol close terlihat jelas
        Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
           colors: [
            Colors.black.withOpacity(0.6), // Gelap di atas
            Colors.transparent,      // Bening di tengah
           ],
           stops: const [0.0, 0.3],
          ),
         ),
        ),
       ],
      ),
     ),

     // 2. TOMBOL CLOSE (Pojok Kanan Atas)
     Positioned(
      top: 50, 
      right: 20,
      child: GestureDetector(
       onTap: () => Navigator.pop(context), 
       child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
         color: Colors.white,
         shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.black, size: 24),
       ),
      ),
     ),

     // 3. SHEET INFORMASI (Bagian Putih di Bawah)
     Align(
      alignment: Alignment.bottomCenter,
      child: Container(
       height: infoContainerHeight, 
       padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
       decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
         topLeft: Radius.circular(40),
         topRight: Radius.circular(40),
        ),
        boxShadow: [
         BoxShadow(
          color: Colors.black26,
          blurRadius: 20,
          offset: Offset(0, -5),
         ),
        ],
       ),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         // A. Tanggal
         Text(
          event.date,
          style: const TextStyle(
           color: AppColors.primary,
           fontWeight: FontWeight.w600,
           fontSize: 14,
          ),
         ),
         const SizedBox(height: 8),

         // B. Judul Kegiatan
         Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
           color: AppColors.textDark,
           fontSize: 24,
           fontWeight: FontWeight.bold,
           height: 1.1,
          ),
         ),
         const SizedBox(height: 8),

         // C. Lokasi
         Row(
          children: [
           const Icon(Icons.location_on, color: Colors.grey, size: 16),
           const SizedBox(width: 4),
           Text(
            event.location,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
           ),
          ],
         ),
         
         const SizedBox(height: 20),

         // D. Deskripsi Singkat (Bisa di-scroll jika panjang)
         Expanded(
          child: SingleChildScrollView(
           physics: const BouncingScrollPhysics(),
           child: Text(
            event.description,
            style: TextStyle(
             color: Colors.grey[600],
             height: 1.5,
             fontSize: 14,
            ),
           ),
          ),
         ),

         const SizedBox(height: 20),

         // E. Dua Tombol (Simpan & Daftar)
         Row(
          children: [
           // Tombol Simpan (Love / Bookmark)
           Container(
            width: 50, // Ukuran sedikit diperbesar agar lebih proporsional
            height: 50,
            decoration: BoxDecoration(
             border: Border.all(color: Colors.grey.shade300, width: 1.5), // Border lebih tebal
             borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
             // Contoh: Tunjukkan bahwa event sudah di-save
             icon: Icon(
              Icons.favorite_border, // Ganti ke Icons.favorite jika sudah tersimpan
              color: AppColors.primary, 
              size: 24,
             ),
             onPressed: () {
              // TODO: Implementasi logika save/unsave ke Firestore
              ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Fitur Save Event belum diimplementasi')),
              );
             },
            ),
           ),
           
           const SizedBox(width: 16),

           // Tombol Daftar (Primary)
           Expanded(
            child: ElevatedButton.icon( // Menggunakan ElevatedButton.icon untuk tampilan yang lebih menarik
             icon: const Icon(Icons.confirmation_number_outlined, size: 20),
             label: const Text(
              "Daftar Sekarang",
              style: TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.bold,
              ),
             ),
             onPressed: () {
              // TODO: Implementasi logika pendaftaran/pembelian tiket
              ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Pendaftaran event "${event.title}"')),
              );
             },
             style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 5,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(15),
              ),
             ),
            ),
           ),
          ],
         ),
        ],
       ),
      ),
     ),
    ],
   ),
  );
 }
}