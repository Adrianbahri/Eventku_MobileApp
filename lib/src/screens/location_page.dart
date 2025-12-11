// File: screens/location_page.dart (ManualLocationSearchPage)
// Pastikan path ini benar di proyek Anda
import '../Utils/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Models/location_model.dart';

class ManualLocationSearchPage extends StatefulWidget {
  // ✅ KOREKSI: Tambahkan kembali API Key sebagai required parameter
  final String googleApiKey; 

  // ✅ KOREKSI: Update konstruktor
  const ManualLocationSearchPage({super.key, required this.googleApiKey}); 

  @override
  State<ManualLocationSearchPage> createState() => _ManualLocationSearchPageState();
}

class _ManualLocationSearchPageState extends State<ManualLocationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _predictions = [];
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _generateSessionToken();
    _searchController.addListener(_onSearchChanged);
  }

  void _generateSessionToken() {
    // Generate token acak untuk Google Maps Billing
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _onSearchChanged() {
    if (_searchController.text.length > 2) {
      _getAutocompletePredictions(_searchController.text);
    } else {
      setState(() => _predictions = []);
    }
  }

  // FUNGSI: Google Maps Autocomplete API Call
  Future<void> _getAutocompletePredictions(String query) async {
    const String baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    
    // Perhatikan: Menggunakan API Key dari widget!
    final String request = '$baseUrl?input=$query&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&components=country:id';

    try {
      final response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          if(mounted) {
            setState(() {
              _predictions = data['predictions'];
            });
          }
        } else {
          debugPrint("Google Maps Autocomplete Error: ${data['status']}");
        }
      }
    } catch (e) {
      debugPrint("HTTP Error during Autocomplete: $e");
    }
  }

  // FUNGSI: Google Maps Details API Call
  Future<void> _getPlaceDetails(String placeId, String description) async {
    const String baseUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
    
    // Perhatikan: Menggunakan API Key dari widget!
    const String fields = 'geometry,name,formatted_address';
    final String request = '$baseUrl?place_id=$placeId&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&fields=$fields';

    try {
      final response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          
          final LocationSearchResult finalResult = LocationSearchResult(
            addressName: description, 
            latitude: location['lat'], 
            longitude: location['lng']
          );
          
          // Kirim hasilnya kembali ke AddEventPage
          if(mounted) {
            Navigator.pop(context, finalResult);
          }
          
        } else {
          debugPrint("Google Maps Details Error: ${data['status']}");
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Gagal mengambil detail lokasi: ${data['status']}")),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("HTTP Error during Details: $e");
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cari Alamat Event"),
        backgroundColor: AppColors.background,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Masukkan alamat atau tempat...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(prediction['description']),
                  onTap: () {
                    // Ambil detail saat item dipilih
                    _getPlaceDetails(prediction['place_id'], prediction['description']);
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