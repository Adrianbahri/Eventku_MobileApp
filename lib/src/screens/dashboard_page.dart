import 'package:flutter/material.dart';
import 'detail_page.dart';
import '../Models/event_model.dart';
import 'add_event_page.dart';
import 'profile_page.dart';
import 'notification_page.dart';
import '../Utils/app_colors.dart';
import 'ticket_page.dart';
import 'favorite_page.dart';
import '../Utils/event_repository.dart'; // Import Repository

// --- Halaman Utama (Dashboard) ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ✅ KOREKSI: Menggunakan getter statis 'instance' untuk mengakses Singleton
  final EventRepository _eventRepo = EventRepository.instance; 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void refreshUI() {
    if (mounted) { 
      setState(() {});
      debugPrint("UI Refreshed: HomePage is mounted.");
    } else {
      debugPrint("UI Refresh Skipped: HomePage is not mounted (disposed).");
    }
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
            CustomHeader(
              onEventAdded: refreshUI,
              searchController: _searchController,
            ),
            
            const Divider(
              height: 1, 
              thickness: 1, 
              color: Color(0xFFE0E0E0),
              indent: 24, 
              endIndent: 24, 
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
                  Expanded(child: _buildEventCarousel()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomFloatingNavBar(onAddEvent: refreshUI), 
    );
  }

  // Widget untuk StreamBuilder dan PageView (Diperbarui menggunakan Repository)
  Widget _buildEventCarousel() {
    return StreamBuilder<List<EventModel>>(
      // ✅ Memanggil method Stream dari Repository
      stream: _eventRepo.getEventsStream(),
      
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

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada event yang tersedia.",
              style: TextStyle(color: AppColors.textDark),
            ),
          );
        }

        // Data yang diterima sudah berupa List<EventModel>
        final List<EventModel> allEvents = snapshot.data!;

        // Filter data berdasarkan query pencarian (Client-Side Filtering)
        final filteredEvents = allEvents.where((event) {
          final titleLower = event.title.toLowerCase();
          final locationLower = event.location.toLowerCase();
          
          return _searchQuery.isEmpty || 
                 titleLower.contains(_searchQuery) || 
                 locationLower.contains(_searchQuery); 
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
                  bottom: 110, 
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
//           WIDGET KOMPONEN
// -------------------------------------------------------------

// --- Kartu Event Responsif ---
class _EventCardResponsive extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String imagePath;

  const _EventCardResponsive({
    required this.title,
    required this.date,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                              const SizedBox(height: 4),
                              Text(
                                "Gagal Memuat",
                                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                              )
                            ],
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      "assets/image/poster1.png", 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
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

// header
class CustomHeader extends StatelessWidget {
  final VoidCallback onEventAdded;
  final TextEditingController searchController; 

  const CustomHeader({super.key, 
    required this.onEventAdded,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // 1. Logo
          Image.asset(
            "assets/image/primarylogo.png",
            height: 35, 
            width: 60, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 10),
          // 2. Search Bar
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Cari Event...", 
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 44, 44, 44), size: 20),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 245, 245, 245),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 3. Ikon Profile
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: const Icon(Icons.account_circle, color: Color.fromARGB(255, 50, 50, 50), size: 35),
          ),
          const SizedBox(width: 10),
          
          // 4. Ikon Notifikasi
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
            child: const Icon(Icons.notifications_none, color: AppColors.textDark, size: 28),
          ),
        ],
      ),
    );
  }
}
// --- Floating Bottom Navigation Bar Kustom ---
class CustomFloatingNavBar extends StatelessWidget {
  final VoidCallback onAddEvent;

  const CustomFloatingNavBar({super.key, required this.onAddEvent});

  Widget _buildNavIcon({
    required IconData icon, 
    required bool isActive, 
    required VoidCallback onTap
  }) {
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    // Properti Responsif untuk Tombol 'Add Event' (Dibuat Lebih Kecil)
    final double horizontalPadding = isSmallScreen ? 10 : 20; 
    final double iconSize = isSmallScreen ? 18 : 22;       
    final double fontSize = isSmallScreen ? 13 : 15;       
    
    // Lebar Grup Ikon Navigasi (Diperkecil)
    final double navGroupWidth = isSmallScreen ? 130 : 140; 

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
      decoration: BoxDecoration(
        color: AppColors.background,
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 1. Tombol Add Event 
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              );
              onAddEvent(); 
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10), 
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
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: iconSize),
                  const SizedBox(width: 4), 
                  Text(
                    "Add Event",
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Jarak fleksibel
          const Spacer(),

          // 2. Kelompok Ikon Navigasi 
          SizedBox(
            width: navGroupWidth, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // BERANDA (Home) - Ikon aktif
                _buildNavIcon(icon: Icons.home_filled, isActive: true, onTap: () {}),
                
                // FAVORIT (Favorite)
                _buildNavIcon(
                  icon: Icons.favorite_border, 
                  isActive: false, 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FavoritePage()),
                    );
                  }
                ),


                // TIKET (Tickets)
                _buildNavIcon(
                  icon: Icons.confirmation_number_outlined, 
                  isActive: false, 
                  onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TicketPage()),
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