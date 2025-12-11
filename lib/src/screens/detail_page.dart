import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Models/event_model.dart';
import '../Utils/app_colors.dart';
import '../Utils/event_repository.dart'; // Event Repository
import '../Utils/favorite_helper.dart'; // Helper untuk status favorit
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DetailPage extends StatefulWidget {
  final EventModel event;

  const DetailPage({super.key, required this.event});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  
  final EventRepository _eventRepo = EventRepository(); 
  
  bool _isRegistered = false;
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  // FUNGSI UTAMA: Memuat Status Pendaftaran dan Favorit
  Future<void> _loadStatus() async {
    if (!mounted) return;

    try {
      final registered = await _eventRepo.checkRegistrationStatus(widget.event.id);
      final favorite = await FavoriteHelper.isFavorite(widget.event.id);

      if (mounted) {
        setState(() {
          _isRegistered = registered;
          _isFavorite = favorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading status: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // FUNGSI: Toggle Status Favorit
  void _toggleFavorite() async {
    if (!mounted) return;

    setState(() => _isFavorite = !_isFavorite);
    await FavoriteHelper.toggleFavorite(widget.event.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? "❤️ Ditambahkan ke Favorit" : "💔 Dihapus dari Favorit"),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // FUNGSI: Mendaftar Event (Menggunakan Repository)
  Future<void> _registerEvent() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // 1. Panggil Repository untuk menyimpan pendaftaran tiket
      await _eventRepo.registerEvent(widget.event);

      // 2. Luncurkan Link Pendaftaran Eksternal (Perbaikan Null Safety)
      final registrationLink = widget.event.registrationLink;
      
      // ✅ PERBAIKAN NULL SAFETY: Cek null dan cek apakah string tersebut tidak kosong
      if (registrationLink != null && registrationLink.isNotEmpty) {
        final url = Uri.parse(registrationLink.trim()); 
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          debugPrint("Could not launch registration link: $registrationLink");
        }
      }

      if (mounted) {
        setState(() {
          _isRegistered = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Anda berhasil terdaftar!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mendaftar: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // FUNGSI: Membatalkan Pendaftaran (Menggunakan Repository)
  Future<void> _cancelRegistration() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      await _eventRepo.cancelRegistration(widget.event.id);

      if (mounted) {
        setState(() {
          _isRegistered = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pembatalan pendaftaran berhasil."),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membatalkan: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
      // Membangun URL geo: yang akan membuka aplikasi peta native (Google Maps/Apple Maps)
      final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)'); 

      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka aplikasi Google Maps.')),
          );
        }
      }
    }
  // FUNGSI: Logic Tombol Bawah
  void _handleActionButton() {
    if (_isRegistered) {
      _cancelRegistration();
    } else {
      _registerEvent();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan teks dan warna tombol aksi berdasarkan status
    final buttonText = _isRegistered ? "Batalkan Pendaftaran" : "Daftar Event Sekarang";
    final buttonColor = _isRegistered ? AppColors.secondary : AppColors.primary;
    final iconAction = _isRegistered ? Icons.cancel : Icons.check_circle;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildEventPoster(),
          _buildContentSection(context),
          _buildFloatingButtons(context),

          // Tombol Aksi Bawah
          _buildBottomActionButton(buttonText, buttonColor, iconAction),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  
  Widget _buildEventPoster() {
    final bool isNetworkImage = widget.event.imagePath.startsWith('http');
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: isNetworkImage
              ? Image.network(
                  widget.event.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[300]),
                )
              : Image.asset(
                  "assets/image/placeholder.png", // Placeholder image
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCircleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            _buildCircleButton(
              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.error : AppColors.textLight,
              onTap: _toggleFavorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = AppColors.textLight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, 
      minChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 100), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul Event
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 15),

                // Informasi Penting (Tanggal & Lokasi)
                _buildInfoRow(
                  Icons.calendar_month,
                  "Tanggal & Waktu",
                  widget.event.date,
                  AppColors.primary,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.location_on,
                  "Lokasi",
                  widget.event.location,
                  AppColors.primary,
                ),
                const SizedBox(height: 25),

                // Status Pendaftaran 
                if (_isRegistered)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      "🎟️ Status: Anda SUDAH terdaftar untuk event ini.",
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),

                // Deskripsi
                const Text(
                  "Deskripsi Event",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Peta (Opsional) 
                if (widget.event.eventLat != null)
                  _buildMapPreview(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoRow(IconData icon, String title, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: MediaQuery.of(context).size.width - 120,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
// File: detail_page.dart (Hanya _buildMapPreview yang dimodifikasi)

// Pastikan Anda sudah mengimplementasikan _openGoogleMaps(lat, lng, label)
// dan memiliki import GoogleMapsFlutter di atas.

  Widget _buildMapPreview() {
    final bool hasCoordinates = widget.event.eventLat != null && widget.event.eventLng != null;

    if (!hasCoordinates) {
      // Mengembalikan placeholder jika koordinat tidak ada
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
          "Lokasi di Peta",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        
        // Peta Mini Interaktif (diambil dari _buildLocationWidget)
        GestureDetector(
          // Panggil fungsi untuk membuka Google Maps Native saat di-tap
          onTap: () => _openGoogleMaps(eventLocation.latitude, eventLocation.longitude, widget.event.location),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                    // Nonaktifkan interaksi agar bisa dibuka di native maps
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
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
        const SizedBox(height: 40),
      ],
    );
  }
  Widget _buildBottomActionButton(String text, Color color, IconData icon) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleActionButton,
            icon: Icon(icon, color: AppColors.textLight),
            label: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}