import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:add_2_calendar/add_2_calendar.dart'; 
import '../Fungsi/event_model.dart'; 
import '../Fungsi/app_colors.dart'; 
import 'detail_page.dart'; // Import DetailPage

// WIDGET UTAMA: Halaman Daftar Tiket - STATEFUL
class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {

  final String _currentUserId = 'user_id_example_123'; 
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
    
    // Placeholder waktu - Ganti dengan waktu event sesungguhnya dari Firestore
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
      SnackBar(content: Text('Event "${title}" ditambahkan ke Kalender!')),
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

    setState(() {
      _selectedTicketIds.clear();
    });

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
        // Asumsi EventModel memiliki konstruktor fromMap yang berfungsi
        final EventModel event = EventModel.fromMap(docSnapshot.data()!, docSnapshot.id);
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
    final eventId = data['eventId'] as String?; // Ambil eventId dari data tiket
    final isSelected = _selectedTicketIds.contains(docId);

    final String title = data['eventTitle'] ?? 'Event Tidak Dikenal';
    final String location = data['eventLocation'] ?? 'Lokasi Tidak Diketahui';
    final Timestamp registrationTimestamp = data['registrationDate'] ?? Timestamp.now();
    final String formattedDate = registrationTimestamp.toDate().toString().split(' ')[0];

    return GestureDetector(
      onLongPress: () => _toggleSelection(docId),
      onTap: _selectedTicketIds.isNotEmpty
          ? () => _toggleSelection(docId)
          // Panggil fungsi navigasi saat diklik (hanya jika tidak dalam mode seleksi)
          : eventId != null 
              ? () => _navigateToDetailPage(context, eventId)
              : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID Event tidak tersedia.')),
                    ),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.35),
                    AppColors.primary.withOpacity(0.15)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.grey.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
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
                  Text(location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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

              // Garis Dashed
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
                        docId.substring(0, 8),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.qr_code, size: 40, color: AppColors.primary),
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
    final CollectionReference registrationRef = 
        FirebaseFirestore.instance.collection('registrations');

    final Query ticketQuery = registrationRef
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('registrationDate', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTicketIds.isEmpty 
            ? 'Tiket Saya' 
            : '${_selectedTicketIds.length} Dipilih'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
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
      
      bottomSheet: _selectedTicketIds.isNotEmpty && _registeredTickets != null 
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  
                  // Tombol Hapus
                  TextButton.icon(
                    onPressed: _deleteSelectedTickets,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Hapus Tiket',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),

                  // Tambah ke kalender (1 tiket)
                  if (_selectedTicketIds.length == 1)
                    TextButton.icon(
                      onPressed: () {
                        final selectedDoc = _registeredTickets!.firstWhere(
                          (doc) => doc.id == _selectedTicketIds.first,
                        );
                        _addToCalendar(context, selectedDoc.data() as Map<String, dynamic>); 
                      },
                      icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                      label: const Text('Tambah ke Kalender',
                          style: TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),

                  // Batal
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTicketIds.clear();
                      });
                    },
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

// Garis putus-putus
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