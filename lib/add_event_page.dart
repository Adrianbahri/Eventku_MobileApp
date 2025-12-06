import 'dart:typed_data'; // Untuk Uint8List (Pengganti File)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_model.dart'; // Pastikan EventModel Anda memiliki properti registrationLink

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
  // 🔥 CONTROLLER BARU UNTUK LINK PENDAFTARAN
  final TextEditingController _regLinkController = TextEditingController(); 

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  Uint8List? _imageBytes; 
  String? _imageName; // Menyimpan nama file asli
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locController.dispose();
    _descController.dispose();
    _regLinkController.dispose(); // 🔥 JANGAN LUPA DISPOSE
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
        final bytes = await picked.readAsBytes();
        
        setState(() {
          _imageBytes = bytes;
          _imageName = picked.name;
        });
      }
    } catch (e) {
      debugPrint("Error pick image: $e");
    }
  }

  // --- LOGIKA SUBMIT (TERMASUK LINK PENDAFTARAN) ---
  void _submitEvent() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap login dahulu!")));
      return;
    }

    // Validasi sederhana (link pendaftaran opsional)
    if (_titleController.text.isEmpty || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi data & gambar!")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload Gambar ke Firebase Storage
      String fileName = '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('posters/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask = storageRef.putData(_imageBytes!, metadata);
      
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // 2. Format Tanggal
      final String formattedDateString = 
        _selectedDate != null && _selectedTime != null 
          ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} ${_selectedTime!.format(context)}"
          : "Tanggal/Waktu Belum Ditentukan";

      // 3. Simpan ke Firestore
      final newEvent = EventModel(
        id: '',
        title: _titleController.text,
        date: formattedDateString,
        location: _locController.text,
        description: _descController.text,
        imagePath: imageUrl,
        userId: currentUserId,
        registrationLink: _regLinkController.text.trim(), // 🔥 DATA BARU DISIMPAN
      );

      await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event Berhasil Dibuat!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- HELPER DATE PICKER ---
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

  // --- HELPER WIDGETS ---
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));
  
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller, 
      maxLines: maxLines, 
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon), 
        hintText: hint, 
        filled: true, 
        fillColor: AppColors.inputBg, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
      )
    );
  }

  Widget _buildPickerContainer({required IconData icon, required String text, required VoidCallback onTap, required bool isActive}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: isActive ? AppColors.primary : Colors.grey), borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(text)])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Event (Web & Android)")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Agar rapi di Layar Lebar (Web)
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
                _buildLabel("Nama Kegiatan"),
                _buildTextField(controller: _titleController, hint: "Nama Event", icon: Icons.event),
                const SizedBox(height: 20),
                
                Row(children: [
                  Expanded(child: _buildPickerContainer(icon: Icons.calendar_today, text: _selectedDate?.toString().split(' ')[0] ?? "Pilih Tgl", onTap: _pickDate, isActive: _selectedDate != null)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPickerContainer(icon: Icons.access_time, text: _selectedTime?.format(context) ?? "Pilih Jam", onTap: _pickTime, isActive: _selectedTime != null)),
                ]),
                
                const SizedBox(height: 20),
                _buildLabel("Lokasi"),
                _buildTextField(controller: _locController, hint: "Lokasi", icon: Icons.location_on),
                
                const SizedBox(height: 20),
                // 🔥 INPUT LINK PENDAFTARAN BARU
                _buildLabel("Link Pendaftaran (Opsional)"),
                _buildTextField(
                  controller: _regLinkController, 
                  hint: "Contoh: https://bit.ly/pendaftaran-event", 
                  icon: Icons.link,
                  keyboardType: TextInputType.url // Keyboard khusus untuk URL
                ),
                
                const SizedBox(height: 20),
                _buildLabel("Poster"),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
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
                _buildTextField(controller: _descController, hint: "Deskripsi", icon: Icons.description, maxLines: 3),

                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16)),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Publikasikan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
      ),
    );
  }
}