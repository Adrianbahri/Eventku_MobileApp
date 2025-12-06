import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_page.dart';
import 'event_model.dart';
import 'add_event_page.dart';
import 'profile_page.dart';

class AppColors {
  static const primary = Color.fromRGBO(232, 0, 168, 1);
  static const background = Color(0xFFF5F5F5);
  static const textDark = Colors.black87;
  static const tertiary = Color(0xFFC70039); // Warna Tambahan untuk Pembeda
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. TAMBAHKAN CONTROLLER UNTUK PENCARIAN
  final TextEditingController _searchController = TextEditingController();
  // State untuk menyimpan query pencarian yang aktif
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 2. LISTEN KE PERUBAHAN INPUT SEARCH
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Dipanggil setiap kali teks di kolom pencarian berubah
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Callback sederhana untuk refresh (jika diperlukan)
  void refreshUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER (Tidak Berubah dari versi sebelumnya, hanya Header Baru)
            CustomHeader(
              onEventAdded: refreshUI,
              searchController: _searchController,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 20,
                      bottom: 10,
                    ),
                    child: Text(
                      "Event Yang Tersedia",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),

                  // CAROUSEL / PAGEVIEW DARI FIREBASE
                  Expanded(child: _buildResponsiveCarousel()),
                ],
              ),
            ),
          ],
        ),
      ),
      // FOOTER BARU DENGAN LAYOUT YANG DIUBAH
      bottomNavigationBar: CustomFloatingNavBar(onAddEvent: refreshUI),
    );
  }

  // Widget untuk membangun StreamBuilder dan PageView
  Widget _buildResponsiveCarousel() {
    // 3. LOGIKA FILTER DATA DI SINI
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          // ✅ Sorting berdasarkan timestamp terbaru
          .orderBy('timestamp', descending: true)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada event yang tersedia.",
              style: TextStyle(color: AppColors.textDark),
            ),
          );
        }

        // Konversi Data dari Firestore ke List<EventModel>
        final List<EventModel> allEvents = snapshot.data!.docs.map((doc) {
          return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // 4. FILTER DATA BERDASARKAN QUERY PENCARIAN (Client-Side Filtering)
        final filteredEvents = allEvents.where((event) {
          final titleLower = event.title.toLowerCase();
          final locationLower = event.location.toLowerCase();
          
          return _searchQuery.isEmpty || 
                 titleLower.contains(_searchQuery) || // Filter Judul
                 locationLower.contains(_searchQuery); // Filter Lokasi
        }).toList();


        if (filteredEvents.isEmpty) {
          return Center(
            child: Text(
              "Tidak ada event yang cocok dengan '$_searchQuery'.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDark),
            ),
          );
        }

        // Tampilkan data menggunakan PageView.builder
        return PageView.builder(
          controller: PageController(viewportFraction: 0.75),
          itemCount: filteredEvents.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final EventModel event = filteredEvents[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(event: event),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 110, // Memberi ruang untuk Bottom Nav Bar
                ),
                child: _EventCardResponsive(
                  title: event.title,
                  date: event.date,
                  location: event.location,
                  imagePath: event.imagePath, 
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
//          WIDGET KOMPONEN TAMBAHAN
// -------------------------------------------------------------

// --- KARTU EVENT RESPONSIF ---
class _EventCardResponsive extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String imagePath;

  const _EventCardResponsive({
    super.key,
    required this.title,
    required this.date,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Cek apakah imagePath tidak kosong dan merupakan URL (https)
    final bool isNetworkImage = imagePath.isNotEmpty && imagePath.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GAMBAR
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: isNetworkImage
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      // Loading Builder
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      // Error Builder dengan Debugging
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint("❌ GAGAL LOAD GAMBAR DARI URL: $imagePath");
                        debugPrint("❌ ERROR DETAIL: $error");
                        
                        return Container(
                          color: Colors.grey[200],
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_moon_outlined, color: Colors.grey, size: 30),
                              const SizedBox(height: 4),
                              Text(
                                "Gagal Memuat (Cek Izin Storage)",
                                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                              )
                            ],
                          ),
                        );
                      },
                    )
                  // Fallback jika bukan URL (Asset Lokal)
                  : Image.asset(
                      "assets/image/poster1.png", 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                         debugPrint("❌ Asset tidak ditemukan: assets/image/poster1.png");
                        return Container(color: Colors.grey[300]);
                      },
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        
        // INFO TEXT
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- CUSTOM HEADER (Ikon Profile & Notifikasi) ---
class CustomHeader extends StatelessWidget {
  final VoidCallback onEventAdded;
  final TextEditingController searchController; 

  const CustomHeader({
    super.key, 
    required this.onEventAdded,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. LOGO
          Image.asset(
            "assets/image/primarylogo.png",
            height: 35, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          
          // 2. SEARCH BAR
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchController, 
                decoration: InputDecoration(
                  hintText: "Search Event atau Lokasi...", 
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  filled: true,
                  fillColor: Colors.grey[100],
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. IKON PROFILE (Navigasi ke ProfilePage)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: const Icon(Icons.person_outline, color: AppColors.textDark, size: 28),
          ),
          const SizedBox(width: 12),
          
          // 4. IKON NOTIFICATION
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifikasi Page akan dikembangkan!")),
              );
            },
            child: const Icon(Icons.notifications_none, color: AppColors.textDark, size: 28),
          ),
        ],
      ),
    );
  }
}

class CustomFloatingNavBar extends StatelessWidget {
  final VoidCallback onAddEvent;

  const CustomFloatingNavBar({super.key, required this.onAddEvent});

  // Helper untuk tombol navigasi kecil
  Widget _buildNavIcon({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            color: isActive ? AppColors.primary : Colors.grey[600], 
            size: 26
          ),
          const SizedBox(height: 4),
          // Tambahkan indikator aktif jika perlu
          if (isActive) 
            Container(
              height: 4, 
              width: 4, 
              decoration: const BoxDecoration(
                color: AppColors.primary, 
                shape: BoxShape.circle
              )
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      // ✅ Padding horizontal dipertahankan agar ada jarak dari tepi
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        // ✅ Ganti mainAxisAlignment menjadi spaceEvenly agar pembagian ruang lebih proporsional
        // Kita kembali menggunakan spaceBetween dan mengatur jarak internal secara manual di Row ikon.
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          // 1. TOMBOL ADD EVENT (KIRI)
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              );
              onAddEvent(); // Refresh UI setelah kembali
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Add Event",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // 2. KELOMPOK 3 IKON NAVIGASI (KANAN)
          // ✅ Menggunakan Row dengan MainAxisAlignment.spaceAround agar ikon memiliki jarak internal yang baik,
          // dan Row ini akan terdorong ke kanan oleh spaceBetween di Row parent.
          // Kita atur lebar Row ini secara manual untuk memastikan ikon tidak terlalu mepet.
          SizedBox(
            width: 160, // Lebar yang diatur agar ikon terdistribusi dengan baik
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // BERANDA (Home) - Ikon aktif
                _buildNavIcon(
                  icon: Icons.home_filled, 
                  isActive: true, 
                  onTap: () {} 
                ),
                
                // FAVORIT (Favorite)
                _buildNavIcon(
                  icon: Icons.favorite_border, 
                  isActive: false, 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Navigasi ke Halaman Favorit")),
                    );
                  }
                ),

                // TIKET (Tickets)
                _buildNavIcon(
                  icon: Icons.confirmation_number_outlined, 
                  isActive: false, 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Navigasi ke Halaman Tiket/Daftar Event")),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}