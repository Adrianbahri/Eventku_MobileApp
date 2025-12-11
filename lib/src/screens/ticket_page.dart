import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:add_2_calendar/add_2_calendar.dart'; 
import '../Models/event_model.dart';
import '../Utils/app_colors.dart';
import '../screens/detail_page.dart'; 
import 'dart:ui'; 


class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {

  // ✅ KOREKSI KRUSIAL: Ambil ID Pengguna dari FirebaseAuth
  // Jika pengguna belum login, nilainya akan menjadi null.
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid; 
  final Set<String> _selectedTicketIds = {}; 
  List<DocumentSnapshot>? _registeredTickets;

  // Toggle select / unselect tiket
  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedTicketIds.contains(docId)) {
        _selectedTicketIds.remove(docId);
      } else {
        _selectedTicketIds.add(docId);
      }
    });
  }

  // Tambahkan event ke kalender
  void _addToCalendar(BuildContext context, Map<String, dynamic> eventData) {
    final String title = eventData['eventTitle'] ?? 'Event Tiket';
    final String location = eventData['eventLocation'] ?? 'Lokasi Tidak Diketahui'; 

    // NOTE: Logika waktu di sini masih menggunakan waktu sekarang. 
    // Idealnya, Anda harus mengambil waktu event dari EventModel yang terhubung.
    final DateTime startTime = DateTime.now().add(const Duration(hours: 1)); 
    final DateTime endTime = startTime.add(const Duration(hours: 2)); 

    final event = Event(
      title: title,
      description: 'Tiket berhasil didaftarkan.',
      location: location,
      startDate: startTime,
      endDate: endTime,
    );

    Add2Calendar.addEvent2Cal(event);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event "$title" ditambahkan ke Kalender!')),
    );
  }

  // Hapus tiket yang dipilih
  Future<void> _deleteSelectedTickets() async {
    if (_selectedTicketIds.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final registrationRef = FirebaseFirestore.instance.collection('registrations');

    for (var docId in _selectedTicketIds) {
      batch.delete(registrationRef.doc(docId));
    }

    await batch.commit();

    if (mounted) {
      setState(() {
        _selectedTicketIds.clear();
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket yang dipilih berhasil dihapus!')),
      );
    }
  }

  // FUNGSI BARU: Mengambil EventModel dan Navigasi ke DetailPage
  Future<void> _navigateToDetailPage(BuildContext context, String eventId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .get();

      if (docSnapshot.exists) {
        // Menggunakan fromJson dari event_model.dart
        final EventModel event = EventModel.fromJson(docSnapshot.data()!, docSnapshot.id); 
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(event: event),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Detail Event tidak ditemukan.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail event: $e')),
        );
      }
    }
  }

  // 🌟 UI IMPROVEMENT: Card Tiket yang lebih modern
  Widget _buildTicketItem(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    final eventId = data['eventId'] as String?; 
    final isSelected = _selectedTicketIds.contains(docId);

    final String title = data['eventTitle'] ?? 'Event Tidak Dikenal';
    final String location = data['eventLocation'] ?? 'Lokasi Tidak Diketahui';
    final Timestamp registrationTimestamp = data['registrationDate'] ?? Timestamp.now();
    // Konversi timestamp ke string tanggal yang sederhana
    final String formattedDate = registrationTimestamp.toDate().toString().split(' ')[0];
      
      // --- Konten Utama Kartu ---
      final ticketContent = Padding(
    padding: const EdgeInsets.all(18.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge "Tiket Saya"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Tiket Saya",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 12),
        // Judul Event
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        // Lokasi Event
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Flexible(child: Text(location, style: const TextStyle(color: Colors.grey, fontSize: 14))),
          ],
        ),

        const SizedBox(height: 6),
        // Waktu Pendaftaran
        Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text('Terdaftar: $formattedDate',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),

        const SizedBox(height: 14),

        // Garis Dashed Bawaan
        CustomPaint(
          painter: DashedBorderPainter(),
          child: const SizedBox(height: 1),
        ),

        const SizedBox(height: 14),

        // Bagian ID dan QR Code
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ID Tiket:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  docId.length > 8 ? docId.substring(0, 8) : docId, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark, 
                  ),
                ),
              ],
            ),
            const Icon(Icons.qr_code, size: 40, color: AppColors.primary),
          ],
        ),
      ],
    ),
  );

    final ticketContainer = Container(
       margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
       decoration: BoxDecoration(
        // Background Putih Solid (Clean)
        color: AppColors.background, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: const [], // Hapus shadow
        // Border solid default
        border: Border.all(color: Colors.grey.shade300, width: 1), 
       ),
       child: ticketContent,
       );

      // --- Pembungkus Dashed Border untuk Selection ---
    return GestureDetector(
    onLongPress: () => _toggleSelection(docId),
    onTap: _selectedTicketIds.isNotEmpty
    ? () => _toggleSelection(docId)
    : eventId != null 
    ? () => _navigateToDetailPage(context, eventId)
    : () => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('ID Event tidak tersedia.')),
    ),
       child: Stack(
        children: [
        // 1. Container Tiket Asli
        ticketContainer,
        
        // 2. Dashed Border Overlay (Hanya saat terpilih)
        if (isSelected)
         Positioned.fill(
         child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: CustomPaint(
          painter: DashedOutlinePainter(
           color: AppColors.secondary, // Warna Biru Tua 100%
           strokeWidth: 2,
           radius: 15,
          ),
          ),
         ),
         ),
        ],
       ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Tampilkan pesan jika pengguna belum login
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tiket Saya'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark,
          elevation: 0.5,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text('Anda harus login untuk melihat tiket Anda.',
              style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    final CollectionReference registrationRef = 
    FirebaseFirestore.instance.collection('registrations');

    // ✅ KOREKSI: Menggunakan ID pengguna asli untuk kueri
    final Query ticketQuery = registrationRef
    .where('userId', isEqualTo: _currentUserId)
    .orderBy('registrationDate', descending: true);

    return Scaffold(
      // PERBAIKAN: Latar Belakang Aplikasi Utama (Scaffold) harus putih bersih
      backgroundColor: AppColors.background, 
      appBar: AppBar(
        title: Text(_selectedTicketIds.isEmpty 
        ? 'Tiket Saya' 
        : '${_selectedTicketIds.length} Dipilih'),
        // Header Putih (Clean Look)
        backgroundColor: AppColors.background, 
        foregroundColor: AppColors.textDark, // Teks Gelap
        elevation: 0.5,
        actions: [
          if (_selectedTicketIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedTicketIds.clear();
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ticketQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Terjadi kesalahan: ${snapshot.error}',
              textAlign: TextAlign.center),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            _registeredTickets = null;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Anda belum mendaftar untuk event apa pun.',
                  style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final registeredTickets = snapshot.data!.docs;
          _registeredTickets = registeredTickets; 

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), 
            itemCount: registeredTickets.length,
            itemBuilder: (context, index) {
              return _buildTicketItem(context, registeredTickets[index]);
            },
          );
        },
      ),

      // BOTTOM SHEET DENGAN SPASI MINIMAL
      bottomSheet: _selectedTicketIds.isNotEmpty && _registeredTickets != null 
      ? Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: AppColors.textLight, 
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15), 
            topRight: Radius.circular(15)
          ),
          border: Border(
            top: BorderSide(color: AppColors.secondary, width: 2), 
          ),
        ),
        child: SafeArea( 
          minimum: const EdgeInsets.only(bottom: 8), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, 
            children: [

              // Tombol Hapus
              TextButton.icon(
                onPressed: _deleteSelectedTickets,
                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                label: const Text('Hapus',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
              ),

              // SPASI MINIMAL
              const SizedBox(width: 8), 

              // Tambah ke kalender (hanya jika 1 tiket dipilih)
              if (_selectedTicketIds.length == 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final selectedDoc = _registeredTickets!.firstWhere(
                        (doc) => doc.id == _selectedTicketIds.first,
                      );
                      _addToCalendar(context, selectedDoc.data() as Map<String, dynamic>); 
                    },
                    icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                    label: const Text('Tambah',
                      style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  // Spasi sebelum tombol batal
                  const SizedBox(width: 8), 
                ],
              ),

              // Tombol Batal
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTicketIds.clear();
                  });
                },
                child: const Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 13)), 
              ),
            ],
          ),
        ),
      )
      : null,
    );
  }
}

// Custom Painter untuk Dashed Outline (Border Putus-putus)
class DashedOutlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  DashedOutlinePainter({required this.color, required this.strokeWidth, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Path untuk outline RRect
    var path = Path()..addRRect(rRect);

    // Menerapkan Dashed Line Effect
    const double dashWidth = 8;
    const double dashSpace = 4;
    double distance = 0.0;

    Path drawPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        drawPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
    
    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(DashedOutlinePainter oldDelegate) => false;
}

// Garis putus-putus bawaan (Dashed Border Painter)
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