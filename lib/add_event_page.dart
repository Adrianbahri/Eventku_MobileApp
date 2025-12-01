import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppColors {
  static const primary = Color.fromRGBO(232, 0, 168, 1);
  static const textDark = Colors.black87;
  static const inputBg = Color(0xFFF9F9F9);
}

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController(); // Controller untuk URL Gambar

  // State Variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _locController.dispose();
    _descController.dispose();
    _imageUrlController.dispose(); // Wajib dispose controller URL
    super.dispose();
  }

  // --- FUNGSI HELPER TANGGAL & WAKTU ---

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatDateTimeNice(DateTime date, TimeOfDay time) {
    const List<String> days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"];
    const List<String> months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agus", "Sep", "Okt", "Nov", "Des"];

    String dayName = days[date.weekday - 1];
    String monthName = months[date.month - 1];
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');

    return "$dayName, ${date.day} $monthName • $hour:$minute";
  }
  
  // --- FUNGSI SUBMIT EVENT (FIRESTORE) ---
  void _submitEvent() async {
    // [PERBAIKAN 1]: Ambil nilai URL dari controller sebelum validasi
    final String imageUrl = _imageUrlController.text.trim();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid; 
    
    // [VALIDASI 1]: Cek status login
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus login untuk membuat event!"), backgroundColor: Colors.red),
      );
      return;
    }

    // [VALIDASI 2]: Cek semua field wajib
    if (_titleController.text.isEmpty ||
        _locController.text.isEmpty ||
        _descController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        imageUrl.isEmpty ||
        !Uri.parse(imageUrl).isAbsolute) { // Validasi URL dasar
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap lengkapi semua data, dan pastikan URL gambar valid.")),
      );
      return;
    }

    final String formattedDateString = _formatDateTimeNice(_selectedDate!, _selectedTime!);

    final newEvent = EventModel(
      id: '', 
      title: _titleController.text,
      date: formattedDateString, 
      location: _locController.text,
      description: _descController.text,
      imagePath: imageUrl, // Menggunakan URL dari input pengguna
      userId: currentUserId, // Menyimpan ID pengguna
    );

    try {
      final firestore = FirebaseFirestore.instance;
      // Kirim data ke Collection 'events'
      await firestore.collection('events').add(newEvent.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event berhasil dipublikasikan!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim event ke Firestore: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- WIDGET BUILDER ---

  @override
  Widget build(BuildContext context) {
    const bool isSubmitting = false; // Gunakan state loading jika diperlukan di masa depan

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Buat Event Baru", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. NAMA KEGIATAN
            _buildLabel("Nama Kegiatan"),
            _buildTextField(
              controller: _titleController,
              hint: "Contoh: Konser Musik John Wick",
              icon: Icons.event,
            ),

            const SizedBox(height: 20),

            // 2. TANGGAL & JAM
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Tanggal"),
                      _buildPickerContainer(
                        icon: Icons.calendar_today,
                        text: _selectedDate == null 
                            ? "Pilih Tgl" 
                            : "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}",
                        onTap: _pickDate,
                        isActive: _selectedDate != null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Jam Mulai"),
                      _buildPickerContainer(
                        icon: Icons.access_time,
                        text: _selectedTime == null 
                            ? "Pilih Jam" 
                            : _selectedTime!.format(context),
                        onTap: _pickTime,
                        isActive: _selectedTime != null,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. LOKASI
            _buildLabel("Tempat Kegiatan"),
            _buildTextField(
              controller: _locController,
              hint: "Contoh: Lincoln Square, NY",
              icon: Icons.location_on,
            ),

            const SizedBox(height: 20),

            // 4. INPUT URL GAMBAR (Pengganti fitur upload)
            _buildLabel("URL Poster"),
            _buildTextField(
              controller: _imageUrlController, 
              hint: "Contoh: https://i.imgur.com/your-poster.jpg",
              icon: Icons.link,
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: 20),

            // 5. DESKRIPSI
            _buildLabel("Deskripsi Singkat"),
            _buildTextField(
              controller: _descController,
              hint: "Jelaskan detail seru mengenai event ini...",
              icon: Icons.description,
              maxLines: 4,
            ),

            const SizedBox(height: 40),

            // 6. TOMBOL SUBMIT
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  isSubmitting ? "Mengirim Data..." : "Publikasikan Event",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 8, bottom: 2), child: Icon(icon, color: AppColors.primary, size: 20)),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPickerContainer({required IconData icon, required String text, required VoidCallback onTap, required bool isActive}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppColors.primary : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Flexible( 
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isActive ? Colors.black87 : Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}