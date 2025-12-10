// eventku/Dahboard/LocationSearchPage.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '/Model/location_models.dart';

class ManualLocationSearchPage extends StatefulWidget {
  final String googleApiKey;
  const ManualLocationSearchPage({super.key, required this.googleApiKey});

  @override
  State<ManualLocationSearchPage> createState() => _ManualLocationSearchPageState();
}

class _ManualLocationSearchPageState extends State<ManualLocationSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placeList = [];
  // Token sesi digunakan untuk mengelompokkan panggilan Autocomplete dan Details
  String _sessionToken = const Uuid().v4(); 
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

  void _onChanged() {
    if (_searchController.text.isEmpty || _searchController.text.length < 3) {
      if (mounted) {
        setState(() {
          _placeList = [];
        });
      }
      return;
    }
    // Membuat token sesi baru jika sudah kosong (misalnya setelah pengambilan detail)
    if (_sessionToken.isEmpty) {
        _sessionToken = uuid.v4();
    }
    _getSuggestions(_searchController.text);
  }

  void _getSuggestions(String input) async {
    try {
      String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      // Tambahkan filter 'components=country:id' untuk saran di Indonesia
      String request = '$baseURL?input=$input&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&components=country:id';
      
      var response = await http.get(Uri.parse(request));
      var data = json.decode(response.body);

      debugPrint('API Status: ${data['status']}');
      
      if (response.statusCode == 200 && data['status'] == 'OK') {
        if (mounted) {
          setState(() {
            _placeList = data['predictions'];
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error API: ${data['status']} - ${data['error_message'] ?? 'Unknown'}')),
          );
          setState(() {
            _placeList = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      if (mounted) {
        setState(() {
          _placeList = [];
        });
      }
    }
  }
  
  Future<void> _getPlaceDetails(String placeId, String primaryText) async {
    String detailsURL = 'https://maps.googleapis.com/maps/api/place/details/json';
    // Meminta geometry (latitude/longitude)
    String detailsRequest = '$detailsURL?place_id=$placeId&key=${widget.googleApiKey}&sessiontoken=$_sessionToken&fields=geometry,name,formatted_address';
    
    var response = await http.get(Uri.parse(detailsRequest));
    var data = json.decode(response.body);
    
    // Akhiri sesi setelah panggilan details berhasil
    if (mounted) {
      setState(() {
        _sessionToken = '';
      });
    }

    if (data['status'] == 'OK' && mounted) {
      final location = data['result']['geometry']['location'];
      
      final result = LocationSearchResult(
        // PENTING: Menggunakan primaryText (nama tempat ringkas) sebagai addressName yang akan disimpan
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi Event (Ringkas)"),
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
                hintText: "Cari Nama Tempat...",
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
          
          Expanded(
            child: ListView.builder(
              itemCount: _placeList.length,
              itemBuilder: (context, index) {
                final prediction = _placeList[index];
                
                final primaryText = prediction['structured_formatting']['main_text'];
                final secondaryText = prediction['structured_formatting']['secondary_text'];

                return ListTile(
                  title: Text(primaryText),
                  subtitle: Text(secondaryText),
                  onTap: () {
                    // Panggil Place Details dan teruskan primaryText
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