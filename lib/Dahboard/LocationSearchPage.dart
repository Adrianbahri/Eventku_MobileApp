import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// PASTIKAN PATH INI SESUAI DI PROYEK ANDA
import '../Fungsi/app_colors.dart'; 
import '/Model/location_models.dart';


// Asumsi: class LocationSearchResult sudah didefinisikan di location_models.dart

class ManualLocationSearchPage extends StatefulWidget {
 final String googleApiKey;
 const ManualLocationSearchPage({super.key, required this.googleApiKey});

 @override
 State<ManualLocationSearchPage> createState() => _ManualLocationSearchPageState();
}

class _ManualLocationSearchPageState extends State<ManualLocationSearchPage> {
 final TextEditingController _searchController = TextEditingController();
 List<dynamic> _placeList = [];
 String _sessionToken = const Uuid().v4(); 
 var uuid = const Uuid();
  bool _isLoading = false; 

 @override
 void initState() {
  super.initState();
  _searchController.addListener(_onChanged);
 }

 @override
 void dispose() {
    _searchController.removeListener(_onChanged);
  _searchController.dispose();
  super.dispose();
 }

// --- LOGIKA PENCARIAN & API ---

 void _onChanged() {
  if (_searchController.text.isEmpty || _searchController.text.length < 3) {
   if (mounted) {
    setState(() {
     _placeList = [];
          _isLoading = false;
    });
   }
   return;
  }
  
  if (_sessionToken.isEmpty) {
    _sessionToken = uuid.v4();
  }
  _getSuggestions(_searchController.text);
 }

 void _getSuggestions(String input) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
  try {
   String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
   String request = '$baseURL?input=$input&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&components=country:id';
   
   var response = await http.get(Uri.parse(request));
   var data = json.decode(response.body);

    if (!mounted) return; 
   
   if (response.statusCode == 200 && data['status'] == 'OK') {
    setState(() {
     _placeList = data['predictions'];
            _isLoading = false;
    });
   } else {
    if (mounted) {
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error API: ${data['status']} - ${data['error_message'] ?? 'Unknown'}')),
     );
     setState(() {
      _placeList = [];
            _isLoading = false;
     });
    }
   }
  } catch (e) {
   debugPrint('Exception during API call: $e');
   if (mounted) {
    setState(() {
     _placeList = [];
          _isLoading = false;
    });
   }
  }
 }
 
 Future<void> _getPlaceDetails(String placeId, String primaryText) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
  String detailsURL = 'https://maps.googleapis.com/maps/api/place/details/json';
  String detailsRequest = '$detailsURL?place_id=$placeId&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&fields=geometry,name,formatted_address';
  
  var response = await http.get(Uri.parse(detailsRequest));
  var data = json.decode(response.body);
  
  
  if (mounted) {
   setState(() {
    _sessionToken = '';
        _isLoading = false;
   });
  } else {
      return;
    }

  if (data['status'] == 'OK' && mounted) {
   final location = data['result']['geometry']['location'];
   
   final result = LocationSearchResult(
    addressName: primaryText, 
    latitude: location['lat'],
    longitude: location['lng'],
   );
   
   Navigator.pop(context, result);
  } else if (mounted) {
   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Gagal mendapatkan Detail Lokasi: ${data['status']}')),
   );
  }
 }

// --- WIDGET STYLING KUSTOM ---

  Widget _buildSearchField() {
    // Definisikan Border Side (Pasif dan Aktif)
    final passiveBorderSide = BorderSide(
      color: AppColors.secondary.withOpacity(0.1), // Biru 10%
      width: 1.5,
    );
    final activeBorderSide = const BorderSide(
      color: AppColors.secondary, // Biru 100%
      width: 1.5,
    );
    
    // Definisikan Border Outline yang digunakan berulang
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    );
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textDark), 
        decoration: InputDecoration(
          hintText: "Cari Nama Tempat...",
          hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.5)),
          
          prefixIcon: Icon(Icons.search, color: AppColors.textDark.withOpacity(0.6)), 
          
          suffixIcon: IconButton(
            icon: Icon(Icons.close, color: AppColors.textDark.withOpacity(0.6)),
            onPressed: () {
              _searchController.clear();
              _onChanged(); 
            },
          ),
          
          filled: true,
          fillColor: AppColors.inputBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0), 
          
          // --- PENERAPAN BORDER YANG DIMINTA ---
          
          // Border default (Pasif 10%)
          border: inputBorder.copyWith(borderSide: passiveBorderSide),

          // Border saat tidak fokus (Pasif 10%)
          enabledBorder: inputBorder.copyWith(borderSide: passiveBorderSide),
          
          // Border saat fokus (Aktif 100%)
          focusedBorder: inputBorder.copyWith(borderSide: activeBorderSide),
        ),
      ),
    );
  }

// --- WIDGET UTAMA (BUILD) ---

 @override
 Widget build(BuildContext context) {
  return Scaffold(
      backgroundColor: AppColors.background,
   appBar: AppBar(
    title: const Text(
          "Pilih Lokasi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
    centerTitle: true,
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textDark,
    elevation: 0.0,
   ),
   body: Column(
    children: [
          // Search Field Kustom
     _buildSearchField(),
          
          
          // Indikator Loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Menampilkan Saran Lokasi
     Expanded(
      child: ListView.separated(
              itemCount: _placeList.length,
              separatorBuilder: (context, index) => const Divider(
                height: 0, 
                indent: 20, 
                endIndent: 20, 
                color: Color(0xFFEEEEEE), 
              ),
       itemBuilder: (context, index) {
        final prediction = _placeList[index];
        
        // Menggunakan structured_formatting untuk tampilan List
        final primaryText = prediction['structured_formatting']['main_text'];
        final secondaryText = prediction['structured_formatting']['secondary_text'];

        return ListTile(
                  leading: const Icon(Icons.location_on, color: AppColors.primary),
         title: Text(
                    primaryText,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16),
                  ),
         subtitle: Text(
                    secondaryText,
                    style: TextStyle(color: AppColors.textDark.withOpacity(0.6), fontSize: 13),
                  ),
         onTap: () {
          _getPlaceDetails(prediction['place_id'], primaryText);
         },
        );
       },
      ),
     ),
    ],
   ),
  );
 }
}