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
  void refreshUI() {}
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
            // HEADER
            CustomHeader(onEventAdded: refreshUI),

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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
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
        final List<EventModel> dataEvents = snapshot.data!.docs.map((doc) {
          return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Tampilkan data menggunakan PageView.builder
        return PageView.builder(
          controller: PageController(viewportFraction: 0.75),
          itemCount: dataEvents.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final EventModel event = dataEvents[index];

            return GestureDetector(
              onTap: () {
                // Navigasi ke DetailPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(event: event),
                  ),
                );
              },
              // PERBAIKAN: Mengganti Container dengan Padding di sekitar _EventCardResponsive.
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 110,
                ), // Padding yang besar ada di sini
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
//          WIDGET KOMPONEN TAMBAHAN
// -------------------------------------------------------------

// --- 2. KARTU EVENT RESPONSIF (DIPERBAIKI UNTUK URL GAMBAR) ---
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
    final bool isNetworkImage = imagePath.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. GAMBAR (Menggunakan Image.network jika berupa URL)
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
              child:
                  isNetworkImage &&
                      imagePath
                          .isNotEmpty // Pastikan URL tidak kosong
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
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text("URL Gambar Tidak Valid"),
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),
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

// --- 3. HEADER DENGAN NAVIGASI ADD EVENT ---
class CustomHeader extends StatelessWidget {
  final VoidCallback onEventAdded;
  const CustomHeader({super.key, required this.onEventAdded});

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
          // Pastikan gambar ini tersedia di folder 'assets/image/'
          Image.asset(
            "assets/image/primarylogo.png",
            height: 45,
            width: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 22,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // TOMBOL ADD (NAVIGASI)
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              );
              onEventAdded();
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

// --- 4. FOOTER / CUSTOM FLOATING NAV BAR ---
class CustomFloatingNavBar extends StatelessWidget {
  const CustomFloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Mendapatkan informasi user saat ini
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
          // BAGIAN PROFIL YANG DIKLIK
          InkWell(
            onTap: () {
              // NAVIGASI KE PROFILE PAGE
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ), // <--- TARGET PAGE
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Halo, $userName!",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // IKON NAVIGASI LAIN
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

// --- 5. VERIFY EMAIL PAGE (Didefinisikan di sini untuk menghindari "Undefined Class") ---
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Future<void> _sendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending email: $e')));
      }
    }
  }

  Future<void> _checkEmailVerified() async {
    // Pastikan user di-reload untuk mendapatkan status verifikasi terbaru
    await FirebaseAuth.instance.currentUser?.reload();
    final isVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (isVerified && mounted) {
      // Ganti ke halaman utama atau root
      Navigator.pushReplacementNamed(context, '/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email belum diverifikasi. Cek inbox Anda.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              const Text(
                'A verification email has been sent to your address. Please check your inbox and spam folder.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _checkEmailVerified,
                child: const Text('Check Verification Status'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _sendVerificationEmail,
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
