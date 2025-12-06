import 'dart:typed_data'; // Untuk Uint8List (Pengganti File)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_model.dart';
// Note: Jangan lupa jalankan flutter pub add image_picker firebase_storage cloud_firestore firebase_auth

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  // --- STATE UNTUK GAMBAR (UNIVERSAL) ---
  Uint8List? _imageBytes; // Data gambar mentah (bytes)
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- LOGIKA PEMILIHAN GAMBAR (ALL PLATFORMS) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Resize agar ringan diupload
        imageQuality: 80,
      );

      if (picked != null) {
        // Baca file sebagai Bytes (Data Mentah)
        final bytes = await picked.readAsBytes();
        
        setState(() {
          _imageBytes = bytes;
          // Nama file tidak lagi disimpan di sini karena akan dibuat unik saat upload
        });
      }
    } catch (e) {
      // Pastikan Anda telah mengkonfigurasi izin (permissions) di Android/iOS
      debugPrint("Error pick image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memilih gambar. Cek izin: $e"))
        );
      }
    }
  }

  // --- LOGIKA SUBMIT EVENT ---
  void _submitEvent() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap login dahulu!")));
      return;
    }

    if (_titleController.text.isEmpty || _imageBytes == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi semua data & gambar!")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. UPLOAD GAMBAR KE FIREBASE STORAGE
      String fileName = '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('posters/$fileName');
      
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      
      // Upload Bytes (Bekerja di Web & Android)
      UploadTask uploadTask = storageRef.putData(_imageBytes!, metadata);
      
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // 2. SIMPAN METADATA KE FIRESTORE
      
      // Format Tanggal dan Waktu
      final String formattedDateString = 
          "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} ${_selectedTime!.format(context)}";

      // Membuat objek EventModel (dengan ID sementara)
      final newEvent = EventModel(
        id: '', // ID dikosongkan karena akan diisi oleh Firestore
        title: _titleController.text,
        date: formattedDateString,
        location: _locController.text,
        description: _descController.text,
        imagePath: imageUrl, // URL yang baru didapatkan
        userId: currentUserId,
        timestamp: null, // Dibiarkan null, akan diisi FieldValue.serverTimestamp()
      );

      // Menggunakan spread operator dan menambahkan 'timestamp' secara terpisah
      await FirebaseFirestore.instance.collection('events').add({
        ...newEvent.toMap(),
        'timestamp': FieldValue.serverTimestamp(), // Untuk sorting yang akurat
      });

      if (mounted) {
        // Berhasil, kembali ke halaman sebelumnya
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event Berhasil Dibuat!")));
      }
    } catch (e) {
      debugPrint("Error saat submit: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: Gagal menyimpan data.")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- HELPER PICKER & WIDGETS ---
  Future<void> _pickDate() async {
      final DateTime? picked = await showDatePicker(
        context: context, initialDate: DateTime.now(),
        firstDate: DateTime.now(), lastDate: DateTime(2101));
      if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));
  
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1}) {
    return TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(prefixIcon: Icon(icon, color: AppColors.primary), hintText: hint, filled: true, fillColor: AppColors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 2))));
  }

  Widget _buildPickerContainer({required IconData icon, required String text, required VoidCallback onTap, required bool isActive}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.inputBg, border: Border.all(color: isActive ? AppColors.primary : Colors.grey[300]!), borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(icon, color: isActive ? AppColors.primary : Colors.grey[600]), const SizedBox(width: 8), Text(text, style: TextStyle(color: isActive ? AppColors.textDark : Colors.grey[600]))])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Event Baru")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
               _buildLabel("Nama Kegiatan"),
               _buildTextField(controller: _titleController, hint: "Nama Event", icon: Icons.event),
               const SizedBox(height: 20),
               
               Row(children: [
                 Expanded(child: _buildPickerContainer(icon: Icons.calendar_today, text: _selectedDate?.toString().split(' ')[0] ?? "Pilih Tanggal", onTap: _pickDate, isActive: _selectedDate != null)),
                 const SizedBox(width: 10),
                 Expanded(child: _buildPickerContainer(icon: Icons.access_time, text: _selectedTime?.format(context) ?? "Pilih Jam", onTap: _pickTime, isActive: _selectedTime != null)),
               ]),
               
               const SizedBox(height: 20),
               _buildLabel("Lokasi"),
               _buildTextField(controller: _locController, hint: "Lokasi", icon: Icons.location_on),
               
               const SizedBox(height: 20),
               _buildLabel("Poster"),
               GestureDetector(
                 onTap: _pickImage,
                 child: Container(
                   height: 200,
                   decoration: BoxDecoration(
                     color: AppColors.inputBg,
                     borderRadius: BorderRadius.circular(15),
                     // Gunakan Image.memory untuk menampilkan Bytes (Universal)
                     image: _imageBytes != null 
                        ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover) 
                        : null,
                   ),
                   child: _imageBytes == null 
                    ? const Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), Text("Upload Poster", style: TextStyle(color: Colors.grey))],
                      )) 
                    : null,
                 ),
               ),

               const SizedBox(height: 20),
               _buildLabel("Deskripsi"),
               _buildTextField(controller: _descController, hint: "Deskripsi Lengkap", icon: Icons.description, maxLines: 3),

               const SizedBox(height: 30),
               ElevatedButton(
                 onPressed: _isSubmitting ? null : _submitEvent,
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                 child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Publikasikan Event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
               )
            ],
          ),
        ),
      ),
    );
  }
}