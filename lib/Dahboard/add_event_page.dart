import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Fungsi/event_model.dart';
import '../Fungsi/app_colors.dart';
import "../Fungsi/locationpicker.dart";
import 'LocationSearchPage.dart';
import '../Model/location_models.dart';


class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _regLinkController = TextEditingController();

  double? _selectedLat;
  double? _selectedLng;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isSubmitting = false;

  // Ganti dengan API Key Anda
  final String _googleApiKey = "AIzaSyCALEINfUjR9VDyyNLbvJ4cdBARglUJm1c";

  @override
  void dispose() {
    _titleController.dispose();
    _locController.dispose();
    _descController.dispose();
    _regLinkController.dispose();
    super.dispose();
  }

  // FUNGSI: Mencari Lokasi (Autocomplete)
  Future<void> _searchLocation() async {
    // PERBAIKAN: Tambahkan pemeriksaan mounted sebelum operasi asinkron
    if (!mounted) return;

    final result = await Navigator.push<LocationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ManualLocationSearchPage(googleApiKey: _googleApiKey),
      ),
    );

    if (result != null && mounted) { // PERBAIKAN: Cek mounted setelah await
      setState(() {
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
        _locController.text = result.addressName;
      });

      // PERBAIKAN: Cek mounted sebelum menampilkan SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lokasi dipilih: ${result.addressName}")),
        );
      }
    }
  }

  // FUNGSI: Pin di Peta (Map Picker)
  Future<void> _pinOnMap() async {
    // PERBAIKAN: Tambahkan pemeriksaan mounted sebelum operasi asinkron
    if (!mounted) return;

    final LatLng initialLocation = _selectedLat != null && _selectedLng != null
      ? LatLng(_selectedLat!, _selectedLng!)
      : const LatLng(-5.1476, 119.4327);

    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(initialLocation: initialLocation),
      ),
    );

    if (result != null && mounted) { // PERBAIKAN: Cek mounted setelah await
      setState(() {
        _selectedLat = result.coordinates.latitude;
        _selectedLng = result.coordinates.longitude;
        _locController.text = result.addressName;
      });

      // PERBAIKAN: Cek mounted sebelum menampilkan SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lokasi dipilih: ${result.addressName}")),
        );
      }
    }
  }

  // FUNGSI _pickImage
  Future<void> _pickImage() async {
    // PERBAIKAN: Tambahkan pemeriksaan mounted sebelum operasi asinkron
    if (!mounted) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (picked != null && mounted) { // PERBAIKAN: Cek mounted setelah await
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

  // FUNGSI _submitEvent
  void _submitEvent() async {
    // PERBAIKAN: Cek mounted di awal fungsi asinkron (Opsional tapi bagus)
    if (!mounted) return; 

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap login dahulu!")));
      return;
    }

    if (_titleController.text.isEmpty || _imageBytes == null || _selectedLat == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi judul, gambar, dan pilih lokasi!")));
      return;
    }

    if (mounted) setState(() => _isSubmitting = true); // PERBAIKAN: Cek mounted

    try {
      String fileName = '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('posters/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask = storageRef.putData(_imageBytes!, metadata);

      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      final String formattedDateString =
        _selectedDate != null && _selectedTime != null
        ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} ${_selectedTime!.format(context)}"
        : "Tanggal/Waktu Belum Ditentukan";

      final newEvent = EventModel(
        id: '',
        title: _titleController.text,
        date: formattedDateString,
        location: _locController.text,
        description: _descController.text,
        imagePath: imageUrl,
        userId: currentUserId,
        registrationLink: _regLinkController.text.trim(),
        eventLat: _selectedLat,
        eventLng: _selectedLng,
      );

      await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());

      if (mounted) { // PERBAIKAN: Cek mounted sebelum navigasi & SnackBar
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event Berhasil Dibuat!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false); // PERBAIKAN: Cek mounted
    }
  }

  // --- HELPER DATE/TIME PICKER & WIDGETS ---
  Future<void> _pickDate() async {
    // PERBAIKAN: Tambahkan pemeriksaan mounted sebelum operasi asinkron
    if (!mounted) return;

    final DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime.now(), lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textLight,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked); // PERBAIKAN: Cek mounted
  }

  Future<void> _pickTime() async {
    // PERBAIKAN: Tambahkan pemeriksaan mounted sebelum operasi asinkron
    if (!mounted) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textLight,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked); // PERBAIKAN: Cek mounted
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textDark
      )
    )
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    // 🔥 WARNA STROKE DENGAN OPASITAS 10% (Pasif)
    final passiveBorderColor = AppColors.secondary.withOpacity(0.1);
    // WARNA STROKE DENGAN OPASITAS 100% (Aktif/Fokus)
    final activeBorderColor = AppColors.secondary.withOpacity(1.0);

    // Border Side Pasif (10%)
    final passiveBorderSide = BorderSide(color: passiveBorderColor, width: 1.5);
    // Border Side Aktif (100%)
    final activeBorderSide = BorderSide(color: activeBorderColor, width: 1.5);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      // Teks yang diketik (typed text) berwarna gelap
      style: const TextStyle(color: AppColors.textDark),
      decoration: InputDecoration(
        // ICON: Selalu PRIMARY (Pink)
        prefixIcon: Icon(icon, color: AppColors.primary),
        hintText: hint,
        // Hint text juga berwarna gelap
        hintStyle: const TextStyle(color: AppColors.textDark),
        filled: true,
        fillColor: AppColors.inputBg,

        // Border default (Pasif) -> Opacity 10%
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: passiveBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: passiveBorderSide, // 10%
        ),
        // Border saat fokus (Aktif) -> Opacity 100%
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: activeBorderSide, // 100%
        ),
      )
    );
  }

  // WIDGET CONTAINER PICKER (Tanggal/Jam/Lokasi)
  Widget _buildPickerContainer({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    // 🔥 WARNA ICON: Selalu PRIMARY (Pink) 100%
    final iconColor = AppColors.primary;
    // 🎯 WARNA TEXT: Gelap
    final textColor = AppColors.textDark;

    // 🔥 BORDER: Secondary 10% (Pasif)
    final borderColor = AppColors.secondary.withOpacity(0.1);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Border diatur 10%
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(15),
          color: AppColors.inputBg,
        ),
        child: Row(
          children: [
            // Gunakan iconColor (PRIMARY)
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                // Gunakan textColor (TEXT DARK)
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationStatusText = (_selectedLat != null && _selectedLng != null)
      ? "Lokasi DIPILIH: ${_locController.text}"
      : "Pilih Lokasi di Peta atau Cari Alamat";

    // Warna statis untuk status text (Success/Secondary)
    final statusTextColor = (_selectedLat != null) ? AppColors.success : AppColors.secondary;

    // 🔥 Border untuk Poster (Opacity 10%)
    final posterBorderColor = AppColors.secondary.withOpacity(0.1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Buat Event (Maps API)"),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [

              _buildLabel("Nama Kegiatan"),
              _buildTextField(
                controller: _titleController,
                hint: "Nama Event",
                icon: Icons.event,
              ),
              const SizedBox(height: 20),

              // Picker Tanggal dan Jam
              Row(children: [
                Expanded(child: _buildPickerContainer(icon: Icons.calendar_today, text: _selectedDate?.toString().split(' ')[0] ?? "Pilih Tgl", onTap: _pickDate)),
                const SizedBox(width: 10),
                Expanded(child: _buildPickerContainer(icon: Icons.access_time, text: _selectedTime?.format(context) ?? "Pilih Jam", onTap: _pickTime)),
              ]),

              const SizedBox(height: 20),
              _buildLabel("Lokasi"),

              // AREA INPUT LOKASI BARU (Dua Tombol Sejajar)
              Row(
                children: [
                  Expanded(child: _buildPickerContainer(
                    icon: Icons.search,
                    text: "Cari Manual",
                    onTap: _searchLocation,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPickerContainer(
                    icon: Icons.map_outlined,
                    text: "Pin di Peta",
                    onTap: _pinOnMap,
                  )),
                ],
              ),

              const SizedBox(height: 10),
              // Status Lokasi yang dipilih
              Text(
                locationStatusText,
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: 12
                ),
              ),
              
              const SizedBox(height: 20),

              // Link Pendaftaran
              _buildLabel("Link Pendaftaran (Opsional)"),
              _buildTextField(
                controller: _regLinkController,
                hint: "Contoh: https://bit.ly/pendaftaran-event",
                icon: Icons.link,
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 20),
              _buildLabel("Poster"),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(15),
                    // POSTER: Border Secondary 10%
                    border: Border.all(color: posterBorderColor, width: 1.5),
                    image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: _imageBytes == null
                    ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // ICON POSTER: Primary 100%
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
                        Text("Upload Poster", style: TextStyle(color: AppColors.primary))
                      ],
                    ))
                    : null,
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel("Deskripsi"),
              // DESKRIPSI: Stroke Secondary 10%/100%, Icon/Text Dark
              _buildTextField(
                controller: _descController,
                hint: "Deskripsi",
                icon: Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSubmitting
                  ? const CircularProgressIndicator(color: AppColors.textLight)
                  : const Text(
                    "Publikasikan",
                    style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)
                  ),
              ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}