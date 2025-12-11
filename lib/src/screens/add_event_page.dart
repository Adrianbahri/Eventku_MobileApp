import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/api_key_loader.dart'; 
import '../Models/event_model.dart';
import '../Utils/app_colors.dart';
import "../Utils/location_picker.dart"; // LocationPickerPage
import '../screens/location_page.dart'; // ManualLocationSearchPage
import '../Models/location_model.dart';
import '../Widget/custom_form_field.dart';
import '../Utils/event_repository.dart';

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

  // 🆕 Instance Repository (Untuk CRUD Event)
  final EventRepository _eventRepo = EventRepository.instance;

  // ✅ Dapatkan API Key dari Loader (Getter Singleton)
  final String _googleApiKey = ApiKeyLoader().googleMapsApiKey; 

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
    if (_googleApiKey.isEmpty) { 
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ERROR: API Key tidak dimuat.")),
            );
        }
        return;
    }
    
    if (!mounted) return;

    final result = await Navigator.push<LocationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ManualLocationSearchPage(googleApiKey: _googleApiKey), 
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
        _locController.text = result.addressName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lokasi dipilih: ${result.addressName}")),
        );
      }
    }
  }

  // FUNGSI: Pin di Peta (Map Picker) (Tetap Sama)
  Future<void> _pinOnMap() async {
    if (!mounted) return;

    final LatLng initialLocation = _selectedLat != null && _selectedLng != null
      ? LatLng(_selectedLat!, _selectedLng!)
      : const LatLng(-5.1476, 119.4327);

    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        // Catatan: LocationPickerPage tidak membutuhkan Google Maps API Key secara langsung
        builder: (context) => LocationPickerPage(initialLocation: initialLocation),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLat = result.coordinates.latitude;
        _selectedLng = result.coordinates.longitude;
        _locController.text = result.addressName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lokasi dipilih: ${result.addressName}")),
        );
      }
    }
  }

  // FUNGSI _pickImage (Tetap Sama)
  Future<void> _pickImage() async {
    if (!mounted) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (picked != null && mounted) {
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

  // FUNGSI _submitEvent (Menggunakan Repository)
  void _submitEvent() async {
    if (_googleApiKey.isEmpty) { 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("API Key belum dimuat. Tidak dapat mempublikasikan.")));
        return;
    }
    
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

    if (mounted) setState(() => _isSubmitting = true);

    try {
      // 1. Upload Gambar ke Firebase Storage
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

      // ✅ MENGGUNAKAN REPOSITORY 
      await _eventRepo.addEvent(newEvent);

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

  // --- HELPER DATE/TIME PICKER & WIDGETS (Tidak Berubah) ---
  
  Future<void> _pickDate() async {
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
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
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
    if (picked != null && mounted) setState(() => _selectedTime = picked);
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


  // WIDGET CONTAINER PICKER (Tanggal/Jam/Lokasi)
  Widget _buildPickerContainer({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final iconColor = AppColors.primary;
    final textColor = AppColors.textDark;
    final borderColor = AppColors.secondary.withOpacity(0.1);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(15),
          color: AppColors.inputBg,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ]
        )
      )
    );
  }
  
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // 🛑 TAMPILKAN ERROR JIKA KUNCI GAGAL DIMUAT (Dari Loader)
    if (_googleApiKey.isEmpty) {
      return const Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: SizedBox(),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Text(
              "FATAL ERROR: Kunci API Google Maps tidak dimuat. Pastikan Anda menjalankan main.dart dan file 'assets/key.json' ada.", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      );
    }
    
    // UI utama dimuat HANYA jika kunci tersedia
    final locationStatusText = (_selectedLat != null && _selectedLng != null)
      ? "Lokasi DIPILIH: ${_locController.text}"
      : "Pilih Lokasi di Peta atau Cari Alamat";

    final statusTextColor = (_selectedLat != null) ? AppColors.success : AppColors.secondary;
    final posterBorderColor = AppColors.secondary.withOpacity(0.1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Buat Event"),
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
              CustomFormField(
                controller: _titleController,
                hintText: "Nama Event",
                prefixIcon: Icons.event,
                label: '', 
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
              CustomFormField(
                controller: _regLinkController,
                hintText: "Contoh: https://bit.ly/pendaftaran-event",
                prefixIcon: Icons.link,
                keyboardType: TextInputType.url,
                label: '', 
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
                    border: Border.all(color: posterBorderColor, width: 1.5),
                    image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: _imageBytes == null
                    ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
              CustomFormField(
                controller: _descController,
                hintText: "Deskripsi",
                prefixIcon: Icons.description,
                maxLines: 3,
                label: '', 
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