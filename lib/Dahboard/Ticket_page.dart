import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:add_2_calendar/add_2_calendar.dart'; 
import '../Fungsi/event_model.dart'; 
import '../Fungsi/app_colors.dart'; 

// WIDGET UTAMA: Halaman Daftar Tiket - STATEFUL
class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  // ⚠️ Ganti ini dengan ID pengguna aktual dari Firebase Auth
  final String _currentUserId = 'user_id_example_123'; 

  // State untuk menyimpan ID dokumen pendaftaran yang dipilih
  final Set<String> _selectedTicketIds = {}; 

  // 💡 STATE BARU: Menyimpan daftar DocumentSnapshot untuk diakses di luar StreamBuilder
  List<DocumentSnapshot>? _registeredTickets;

  // FUNGSI: Mengelola pemilihan tiket
  void _toggleSelection(String docId) {
    setState(() {
      if (_selectedTicketIds.contains(docId)) {
        _selectedTicketIds.remove(docId);
      } else {
        _selectedTicketIds.add(docId);
      }
    });
  }

  // 💡 FUNGSI DIPERBAIKI: Menambahkan Event ke Kalender (Sekarang menerima context)
  void _addToCalendar(BuildContext context, Map<String, dynamic> eventData) {
    // ⚠️ Anda harus memastikan eventData memiliki data tanggal dan waktu yang akurat
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
      SnackBar(content: Text('Event "$title" ditambahkan ke Kalender!')),
    );
  }

  // FUNGSI: Menghapus Tiket yang dipilih dari Firestore
  Future<void> _deleteSelectedTickets() async {
    if (_selectedTicketIds.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final registrationRef = FirebaseFirestore.instance.collection('registrations');

    for (var docId in _selectedTicketIds) {
      batch.delete(registrationRef.doc(docId));
    }

    await batch.commit();

    // Reset selection state setelah penghapusan
    setState(() {
      _selectedTicketIds.clear();
      // Tidak perlu reset _registeredTickets, StreamBuilder akan me-refresh.
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket yang dipilih berhasil dihapus!')),
      );
    }
  }
  
  // WIDGET PEMBANTU: Item Daftar Tiket (Tampilan Modern)
  Widget _buildTicketItem(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    final isSelected = _selectedTicketIds.contains(docId);

    final String title = data['eventTitle'] ?? 'Event Tidak Dikenal';
    final String location = data['eventLocation'] ?? 'Lokasi Tidak Diketahui'; 
    final Timestamp registrationTimestamp = data['registrationDate'] ?? Timestamp.now();
    final String formattedDate = registrationTimestamp.toDate().toString().split(' ')[0]; 

    return GestureDetector(
      onLongPress: () => _toggleSelection(docId),
      onTap: _selectedTicketIds.isNotEmpty 
          ? () => _toggleSelection(docId)
          : () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Membuka detail tiket: $title')),
            ),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.textLight,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
          boxShadow: isSelected 
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10)]
              : [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul & Lokasi
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              // Detail Waktu/Lokasi
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text('Terdaftar: $formattedDate', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Pembatas untuk Tampilan Tiket
              CustomPaint(
                painter: DashedBorderPainter(),
                child: const SizedBox(height: 1),
              ),
              
              const SizedBox(height: 10),

              // ID dan QR Code Placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID Tiket:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text(docId.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Icon(Icons.qr_code, size: 36, color: AppColors.primary),
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
        backgroundColor: _selectedTicketIds.isEmpty ? AppColors.primary : AppColors.primary.withOpacity(0.8),
        foregroundColor: AppColors.textLight,
        actions: [
          if (_selectedTicketIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                 setState(() {
                    _selectedTicketIds.clear(); // Tombol Batal/Close Selection
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
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', textAlign: TextAlign.center));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // 💡 PENTING: Jika data kosong, pastikan state list juga null/kosong
            _registeredTickets = null;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Anda belum mendaftar untuk event apa pun.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 💡 FIX CAKUPAN (SCOPE): Simpan data ke state variable
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
      
      // BOTTOM ACTION BAR untuk opsi Kalender dan Hapus
      // 💡 FIX CAKUPAN (SCOPE): Menggunakan _registeredTickets dan mengecek null
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
                    label: const Text('Hapus Tiket', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),

                  // Tombol Tambahkan ke Kalender (Hanya jika 1 tiket dipilih)
                  if (_selectedTicketIds.length == 1)
                    TextButton.icon(
                      onPressed: () {
                        // Cari data tiket yang dipilih dari state variable
                        final selectedDoc = _registeredTickets!.firstWhere(
                          (doc) => doc.id == _selectedTicketIds.first,
                        );
                        // 💡 FIX: Panggil _addToCalendar dengan context
                        _addToCalendar(context, selectedDoc.data() as Map<String, dynamic>); 
                      },
                      icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                      label: const Text('Tambah ke Kalender', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  
                  // Tombol Batalkan Seleksi
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

// Custom Painter untuk Garis Putus-putus (Dashed Border) - Tidak diubah
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