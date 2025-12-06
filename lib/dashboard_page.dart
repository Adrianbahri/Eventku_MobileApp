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
            // HEADER - KIRIMKAN CONTROLLER KE SINI
            CustomHeader(
              onEventAdded: refreshUI,
              searchController: _searchController, // ✅ DIKIRIM KE HEADER
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
      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: const CustomFloatingNavBar(),
    );
  }

  // Widget untuk membangun StreamBuilder dan PageView
  Widget _buildResponsiveCarousel() {
    // 3. LOGIKA FILTER DATA DI SINI
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          // ✅ PERBAIKAN: Sorting berdasarkan timestamp terbaru
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
          // Mengambil data dan ID dokumen
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
          itemCount: filteredEvents.length, // ✅ Menggunakan data yang sudah difilter
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final EventModel event = filteredEvents[index]; // ✅ Menggunakan data yang sudah difilter

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

// --- KARTU EVENT RESPONSIF (Disesuaikan untuk URL Firebase Storage) ---
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
                        // ---------------------------------------------
                        debugPrint("❌ GAGAL LOAD GAMBAR DARI URL: $imagePath");
                        debugPrint("❌ ERROR DETAIL: $error");
                        // ---------------------------------------------
                        
                        return Container(
                          color: Colors.grey[200],
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_moon_outlined, color: Colors.grey, size: 30),
                              const SizedBox(height: 4),
                              Text(
                                "Gagal Memuat (Cek Izin Storage)", // Pesan yang lebih spesifik
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
// --- HEADER ---
class CustomHeader extends StatelessWidget {
  final VoidCallback onEventAdded;
  // 5. TAMBAHKAN CONTROLLER DI CUSTOM HEADER
  final TextEditingController searchController; 

  const CustomHeader({
    super.key, 
    required this.onEventAdded,
    required this.searchController, // ✅ PERUBAHAN
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
          // Logo (Pastikan aset ada)
          Image.asset(
            "assets/image/primarylogo.png",
            height: 45,
            width: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => 
               const Icon(Icons.calendar_month, color: AppColors.primary, size: 30), // ✅ Fallback icon yang lebih baik
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              // 6. PASANG CONTROLLER KE TEXTFIELD
              controller: searchController, 
              decoration: InputDecoration(
                hintText: "Search Event atau Lokasi...", // ✅ Pesan yang lebih baik
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                filled: true,
                fillColor: Colors.grey[100],
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // TOMBOL ADD
          InkWell(
            onTap: () async {
              // Navigasi ke AddEventPage yang sudah Anda buat
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              );
              onEventAdded(); // Refresh UI setelah kembali
            },
            child: Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// --- FOOTER / NAVBAR ---
class CustomFloatingNavBar extends StatelessWidget {
  const CustomFloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'User';

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  "Halo, $userName!",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Icon(Icons.confirmation_number_outlined, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Icon(Icons.settings_outlined, color: Colors.grey[600]),
            ],
          ),
        ],
      ),
    );
  }
}