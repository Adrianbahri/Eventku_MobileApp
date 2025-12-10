import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Fungsi/event_model.dart';
import '../Fungsi/app_colors.dart';
import '../Fungsi/favorite_helper.dart'; // <<< Import FavoriteHelper

// --- Halaman Detail (StatefulWidget) ---
class DetailPage extends StatefulWidget {
  final EventModel event;
  const DetailPage({super.key, required this.event});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final String _currentUserId = 'user_id_example_123'; 
  bool _isFavorite = false; // <<< Status Favorit

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  // Cek status favorit saat halaman dimuat
  Future<void> _checkFavoriteStatus() async {
    final bool status = await FavoriteHelper.isFavorite(widget.event.id);
    setState(() {
      _isFavorite = status;
    });
  }

  // FUNGSI BARU: Toggle status favorit
  Future<void> _toggleFavorite() async {
    await FavoriteHelper.toggleFavorite(widget.event.id);
    final bool status = await FavoriteHelper.isFavorite(widget.event.id);
    setState(() {
      _isFavorite = status;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '✨ Event ditambahkan ke Favorit!' : '🗑️ Event dihapus dari Favorit.'),
          backgroundColor: _isFavorite ? AppColors.primary : Colors.grey,
        ),
      );
    }
  }


  // FUNGSI: Membuka URL pendaftaran di browser
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

  // FUNGSI BARU: Meluncurkan Aplikasi Google Maps Native
  Future<void> _openGoogleMaps(BuildContext context, double lat, double lng, String label) async {
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

  // FUNGSI: Mendaftar di Firestore lalu membuka URL
  Future<void> _registerAndLaunchUrl(BuildContext context) async {
    if (widget.event.registrationLink == null || widget.event.registrationLink!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link pendaftaran belum tersedia!')),
      );
      return;
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      Map<String, dynamic> registrationData = {
        'userId': _currentUserId,
        'eventId': widget.event.id, 
        'eventTitle': widget.event.title,
        'registrationDate': FieldValue.serverTimestamp(),
        'status': 'registered',
      };

      await firestore.collection('registrations').add(registrationData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Berhasil Mendaftar! Membuka link...'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _launchUrl(context, widget.event.registrationLink);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftar di Firestore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _launchUrl(context, widget.event.registrationLink);
    }
  }

  // WIDGET PEMBANTU: Menampilkan gambar jaringan atau fallback
  Widget _buildEventImage(double height) {
    final bool isNetworkImage = widget.event.imagePath.startsWith('http');
    
    if (!isNetworkImage || widget.event.imagePath.isEmpty) {
      return Container(
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
        ),
      );
    }

    return Image.network(
      widget.event.imagePath,
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

  // WIDGET PEMBANTU: Tombol Close
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

  // WIDGET PEMBANTU: Tombol Aksi (Simpan & Daftar) (Diperbarui)
  Widget _buildActionButtons(BuildContext context) {
    final bool isRegistrationLinkAvailable = widget.event.registrationLink != null && widget.event.registrationLink!.isNotEmpty;

    return Row(
      children: [
        // Tombol Simpan (Love / Bookmark) - Diperbarui
        Container(
          width: 50, 
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1.5), 
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border, // <<< Ganti Ikon
              color: _isFavorite ? Colors.red : AppColors.primary, // <<< Ganti Warna
              size: 24
            ),
            onPressed: _toggleFavorite, // <<< Panggil fungsi toggle
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

  // WIDGET BARU: Menampilkan Peta Mini dan Tombol Aksi Lokasi
  Widget _buildLocationWidget(BuildContext context) {
    // Cek apakah koordinat tersedia
    final bool hasCoordinates = widget.event.eventLat != null && widget.event.eventLng != null;

    if (!hasCoordinates) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Koordinat lokasi belum tersedia untuk event ini.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    final LatLng eventLocation = LatLng(widget.event.eventLat!, widget.event.eventLng!);

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
          onTap: () => _openGoogleMaps(context, eventLocation.latitude, eventLocation.longitude, widget.event.location),
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
                        infoWindow: InfoWindow(title: widget.event.location),
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

  // WIDGET PEMBANTU: Sheet Informasi Detail
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
            // A. Tanggal & Judul & Lokasi
            Text(widget.event.date, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Text(widget.event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDark, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.location_on, color: Colors.grey, size: 16), const SizedBox(width: 4), Text(widget.event.location, style: const TextStyle(color: Colors.grey, fontSize: 14))]),
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
                      widget.event.description,
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
    final double infoContainerHeight = screenHeight * 0.5;
    
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