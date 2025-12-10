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

 final String _googleApiKey = "AIzaSyCALEINfUjR9VDyyNLbvJ4cdBARglUJm1c"; // Pastikan API Key Anda dimasukkan di sini

 @override
 void dispose() {
  _titleController.dispose();
  _locController.dispose();
  _descController.dispose();
  _regLinkController.dispose();
  super.dispose();
 }

 // 🔥 FUNGSI _pickLocation dengan pemeriksaan mounted
 Future<void> _pickLocation() async {
  final selectedPage = await showModalBottomSheet<int>(
   context: context,
   builder: (BuildContext context) {
    return Column(
     mainAxisSize: MainAxisSize.min,
     children: <Widget>[
      ListTile(
       leading: const Icon(Icons.search),
       title: const Text('Cari Lokasi dengan Autocomplete (DEBUG)'),
       onTap: () => Navigator.pop(context, 1), 
      ),
      ListTile(
       leading: const Icon(Icons.map),
       title: const Text('Pilih Lokasi di Peta (Map Picker)'),
       onTap: () => Navigator.pop(context, 2), 
      ),
     ],
    );
   },
  );

  // ✅ Cek mounted setelah showModalBottomSheet
  if (!mounted) return; 

  if (selectedPage == 1) {
   // Asumsi ManualLocationSearchPage ada di scope
   final result = await Navigator.push<LocationSearchResult>( 
    context,
    MaterialPageRoute(
     // Anda harus memastikan ManualLocationSearchPage ada di scope atau ganti dengan LocationSearchPage
     builder: (context) => ManualLocationSearchPage(googleApiKey: _googleApiKey),
    ),
   );

   // ✅ Cek mounted sebelum setState setelah Navigator.push
   if (result != null && mounted) {
    setState(() {
     _selectedLat = result.latitude;
     _selectedLng = result.longitude;
     _locController.text = result.addressName; 
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text("Lokasi dipilih: ${result.addressName}")),
    );
   }

  } else if (selectedPage == 2) {
   // === OPSI 2: Lari ke Map Picker LAMA ===
   final LatLng initialLocation = _selectedLat != null && _selectedLng != null 
     ? LatLng(_selectedLat!, _selectedLng!) 
     : const LatLng(-5.1476, 119.4327); 

   final result = await Navigator.push<LocationResult>(
    context,
    MaterialPageRoute(
     builder: (context) => LocationPickerPage(initialLocation: initialLocation),
    ),
   );

   // ✅ Cek mounted sebelum setState setelah Navigator.push
   if (result != null && mounted) {
    setState(() {
     _selectedLat = result.coordinates.latitude;
     _selectedLng = result.coordinates.longitude;
     _locController.text = result.addressName; 
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text("Lokasi dipilih: ${result.addressName}")),
    );
   }
  }
 }


 // 🔥 FUNGSI _pickImage dengan pemeriksaan mounted
 Future<void> _pickImage() async {
  final ImagePicker picker = ImagePicker();
  try {
   final XFile? picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 800, 
    imageQuality: 80,
   );

   // ✅ Cek mounted sebelum setState setelah await
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

 // 🔥 FUNGSI _submitEvent dengan perbaikan newEvent dan pemeriksaan mounted
 void _submitEvent() async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  if (currentUserId == null) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap login dahulu!")));
   return;
  }

  if (_titleController.text.isEmpty || _imageBytes == null || _selectedLat == null) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi judul, gambar, dan pilih lokasi!")));
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

   // ✅ PERBAIKAN: Deklarasi dan inisialisasi newEvent
   final newEvent = EventModel(
    id: '',
    title: _titleController.text,
    date: formattedDateString,
    location: _locController.text, // Nama lokasi
    description: _descController.text,
    imagePath: imageUrl,
    userId: currentUserId,
    registrationLink: _regLinkController.text.trim(), 
    eventLat: _selectedLat, // Koordinat
    eventLng: _selectedLng, // Koordinat
   );

   // 3. Simpan ke Firestore
   await FirebaseFirestore.instance.collection('events').add(newEvent.toMap());

   // ✅ Cek mounted setelah semua operasi asinkron
   if (mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event Berhasil Dibuat!")));
   }
  } catch (e) {
   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
  } finally {
   // ✅ Cek mounted sebelum setState di blok finally
   if (mounted) setState(() => _isSubmitting = false); 
  }
 }

 // --- HELPER DATE/TIME PICKER & WIDGETS ---
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
 
 Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
  return TextField(
   controller: controller, 
   maxLines: maxLines, 
   readOnly: readOnly,
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
  final locationStatusText = (_selectedLat != null && _selectedLng != null)
    ? "Lokasi DIPILIH (${_selectedLat!.toStringAsFixed(2)}, ${_selectedLng!.toStringAsFixed(2)})"
    : "Pilih Lokasi di Peta atau Cari Alamat";

  return Scaffold(
   appBar: AppBar(title: const Text("Buat Event (Maps API)")),
   body: Center(
    child: ConstrainedBox(
     constraints: const BoxConstraints(maxWidth: 600),
     child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
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
        
        // AREA INPUT LOKASI 
        Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Expanded(
           child: _buildTextField(
            controller: _locController, 
            hint: "Nama Lokasi/Alamat", 
            icon: Icons.location_on,
            readOnly: true, // ReadOnly karena diisi oleh picker/autocomplete
           ),
          ),
          const SizedBox(width: 10),
          // Tombol Cari Lokasi
          Container(
           height: 58, 
           decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.primary,
           ),
           child: IconButton(
            onPressed: _pickLocation, // Memanggil fungsi pemilih opsi
            icon: const Icon(Icons.search, color: AppColors.textLight),
            tooltip: "Cari atau Pilih Lokasi",
           ),
          ),
         ],
        ),
        
        const SizedBox(height: 10),
        // Status Lokasi yang dipilih
        Text(
         locationStatusText, 
         style: TextStyle(color: (_selectedLat != null) ? Colors.green.shade700 : Colors.red.shade700, fontSize: 12),
        ),

        const SizedBox(height: 20),
        
        // BAGIAN SISA FORM (dapat digulir)
        Expanded(
         child: ListView(
          padding: EdgeInsets.zero, 
          children: [
           _buildLabel("Link Pendaftaran (Opsional)"),
           _buildTextField(
            controller: _regLinkController, 
            hint: "Contoh: https://bit.ly/pendaftaran-event", 
            icon: Icons.link,
            keyboardType: TextInputType.url 
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
       ],
      ),
     ),
    ),
   ),
  );
 }
}