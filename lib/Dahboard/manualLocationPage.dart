import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// Asumsi model ini ada di location_models.dart atau dideklarasikan di sini
class LocationSearchResult {
  final String addressName;
  final double latitude;
  final double longitude;

  LocationSearchResult({required this.addressName, required this.latitude, required this.longitude});
}

class ManualLocationSearchPage extends StatefulWidget {
  final String googleApiKey;
  const ManualLocationSearchPage({super.key, required this.googleApiKey});

  @override
  State<ManualLocationSearchPage> createState() => _ManualLocationSearchPageState();
}

class _ManualLocationSearchPageState extends State<ManualLocationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placeList = [];
  String _sessionToken = const Uuid().v4(); // Generate token awal
  var uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dipanggil saat input berubah
  void _onChanged() {
    if (_searchController.text.isEmpty || _searchController.text.length < 3) {
      setState(() {
        _placeList = [];
      });
      return;
    }
    // Jika sesi berakhir (setelah pemilihan), buat token baru
    if (_sessionToken.isEmpty) {
        _sessionToken = uuid.v4();
    }
    _getSuggestions(_searchController.text);
  }

  // Fungsi HTTP langsung ke Google Places Autocomplete API
  void _getSuggestions(String input) async {
    try {
      String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      // Meneruskan sessiontoken dan batasan negara (ccTLD Indonesia = id)
      String request = '$baseURL?input=$input&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&components=country:id';
      
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      // 🔥 LOGGING: Cek output ini di Debug Console!
      debugPrint('API Status: ${data['status']}');
      debugPrint('Error Message: ${data['error_message']}'); 

      if (response.statusCode == 200 && data['status'] == 'OK') {
        setState(() {
          _placeList = data['predictions'];
        });
      } else {
        // Tampilkan pesan error API jika ada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error API: ${data['status']} - ${data['error_message'] ?? 'Unknown'}')),
        );
        setState(() {
          _placeList = [];
        });
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      setState(() {
        _placeList = [];
      });
    }
  }
  
  // Fungsi untuk mengambil detail tempat (Place Details API)
  Future<void> _getPlaceDetails(String placeId, String description) async {
    String detailsURL = 'https://maps.googleapis.com/maps/api/place/details/json';
    // Gunakan Place ID dan token yang sama untuk penagihan sesi yang benar
    String detailsRequest = '$detailsURL?place_id=$placeId&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&fields=geometry,name,formatted_address';
    
    var response = await http.get(Uri.parse(detailsRequest));
    var data = json.decode(response.body);
    
    // 🔥 PENTING: Sesi berakhir setelah panggilan Place Details
    setState(() {
      _sessionToken = '';
    });

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      
      final result = LocationSearchResult(
        addressName: data['result']['formatted_address'] ?? description,
        latitude: location['lat'],
        longitude: location['lng'],
      );
      // Kirim hasil kembali ke AddEventPage
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan Detail Lokasi: ${data['status']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi Event (Manual Debug)"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Lokasi/Alamat...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Menampilkan Saran Lokasi
          Expanded(
            child: ListView.builder(
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                final prediction = _placeList[index];
                return ListTile(
                  title: Text(prediction['description']),
                  onTap: () {
                    // Panggil Place Details untuk mendapatkan koordinat
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