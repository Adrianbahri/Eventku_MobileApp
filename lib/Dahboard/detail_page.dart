import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart'; // 💡 Import Google Maps
import '../Fungsi/event_model.dart';
import '../Fungsi/app_colors.dart';

class DetailPage extends StatelessWidget {
  final EventModel event;
  const DetailPage({super.key, required this.event});

  final String _currentUserId = 'user_id_example_123'; 

  // FUNGSI: Membuka URL pendaftaran di browser (Tidak diubah)
  Future<void> _launchUrl(BuildContext context, String? urlString) async {
    // ... kode launchUrl yang sudah ada ...
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link pendaftaran belum tersedia!')),
      );
      return;
    }

    Uri url = Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
        );
      }
    }
  }

  // 💡 FUNGSI BARU: Meluncurkan Aplikasi Google Maps Native
  Future<void> _openGoogleMaps(BuildContext context, double lat, double lng, String label) async {
    // Menggunakan schema 'geo:' untuk membuka Maps native
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');

    if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi Google Maps.')),
        );
      }
    }
  }

  // FUNGSI: Mendaftar di Firestore lalu membuka URL (Tidak diubah)
  Future<void> _registerAndLaunchUrl(BuildContext context) async {
    // ... kode registrasi ke Firestore yang sudah ada ...
    if (event.registrationLink == null || event.registrationLink!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link pendaftaran belum tersedia!')),
      );
      return;
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      Map<String, dynamic> registrationData = {
        'userId': _currentUserId,
        'eventId': event.id, 
        'eventTitle': event.title,
        'registrationDate': FieldValue.serverTimestamp(),
        'status': 'registered',
      };

      await firestore.collection('registrations').add(registrationData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Berhasil Mendaftar! Membuka link...'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _launchUrl(context, event.registrationLink);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftar di Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _launchUrl(context, event.registrationLink);
    }
  }

  // WIDGET PEMBANTU: Menampilkan gambar jaringan atau fallback (Tidak diubah)
  Widget _buildEventImage(double height) {
    // ... kode yang sudah ada ...
    final bool isNetworkImage = event.imagePath.startsWith('http');
    
    if (!isNetworkImage || event.imagePath.isEmpty) {
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

  // WIDGET PEMBANTU: Tombol Close (Tidak diubah)
  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 50, 
      right: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context), 
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.textLight, 
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: AppColors.textDark, size: 24),
        ),
      ),
    );
  }

  // WIDGET PEMBANTU: Tombol Aksi (Simpan & Daftar) (Tidak diubah, memanggil fungsi registrasi)
  Widget _buildActionButtons(BuildContext context) {
    final bool isRegistrationLinkAvailable = event.registrationLink != null && event.registrationLink!.isNotEmpty;

    return Row(
      children: [
        // Tombol Simpan (Love / Bookmark)
        Container(
          width: 50, 
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1.5), 
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border, color: AppColors.primary, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur Save Event belum diimplementasi')),
              );
            },
          ),
        ),

        const SizedBox(width: 16),

        // Tombol Daftar (Primary)
        Expanded(
          child: ElevatedButton.icon( 
            icon: Icon(isRegistrationLinkAvailable ? Icons.open_in_new : Icons.link_off, size: 20),
            label: Text(
              isRegistrationLinkAvailable ? "Daftar Sekarang" : "Link Tidak Tersedia",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: isRegistrationLinkAvailable 
              ? () => _registerAndLaunchUrl(context) 
              : null, 
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
              elevation: 5,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              disabledBackgroundColor: Colors.grey.shade400,
              disabledForegroundColor: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // 💡 WIDGET BARU: Menampilkan Peta Mini dan Tombol Aksi Lokasi
  Widget _buildLocationWidget(BuildContext context) {
    // Cek apakah koordinat tersedia
    final bool hasCoordinates = event.eventLat != null && event.eventLng != null;

    if (!hasCoordinates) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Koordinat lokasi belum tersedia untuk event ini.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    final LatLng eventLocation = LatLng(event.eventLat!, event.eventLng!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lihat Lokasi:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        
        // Peta Mini yang dapat diklik
        GestureDetector(
          onTap: () => _openGoogleMaps(context, eventLocation.latitude, eventLocation.longitude, event.location),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: eventLocation,
                      zoom: 14.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('event_marker'),
                        position: eventLocation,
                        infoWindow: InfoWindow(title: event.location),
                      ),
                    },
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    // Non-interaktif
                    onMapCreated: (controller) {},
                  ),
                  // Overlay Tap-to-Open
                  Container(
                    alignment: Alignment.center,
                    color: Colors.black.withOpacity(0.1),
                    child: const Icon(
                      Icons.near_me, 
                      color: AppColors.textLight, 
                      size: 40
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET PEMBANTU: Sheet Informasi Detail (Diubah untuk menampung Map Widget)
  Widget _buildInfoSheet(BuildContext context, double infoContainerHeight) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: infoContainerHeight, 
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.textLight, 
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
            // A. Tanggal & Judul & Lokasi (Tidak diubah)
            Text(event.date, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.location_on, color: Colors.grey, size: 16), const SizedBox(width: 4), Text(event.location, style: const TextStyle(color: Colors.grey, fontSize: 14))]),
            const SizedBox(height: 20),

            // D. Deskripsi Singkat
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Deskripsi Utama
                    Text(
                      event.description,
                      style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    // 2. WIDGET PETA
                    _buildLocationWidget(context),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // E. Dua Tombol (Simpan & Daftar)
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double imageContainerHeight = screenHeight * 0.65;
    // Tingkatkan infoContainerHeight agar dapat menampung peta
    final double infoContainerHeight = screenHeight * 0.5; // Ditingkatkan dari 0.45 menjadi 0.5
    
    return Scaffold(
      body: Stack(
        children: [
          // 1. GAMBAR POSTER
          Positioned(
            top: 0, left: 0, right: 0, height: imageContainerHeight, 
            child: Stack(fit: StackFit.expand, children: [_buildEventImage(imageContainerHeight), 
              Container(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, 
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent], stops: const [0.0, 0.3])))]),
          ),
          // 2. TOMBOL CLOSE
          _buildCloseButton(context),
          // 3. SHEET INFORMASI
          _buildInfoSheet(context, infoContainerHeight),
        ],
      ),
    );
  }
}