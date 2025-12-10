import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // 💡 Import Geocoding

// Definisi Model untuk mengembalikan hasil
class LocationResult {
  final LatLng coordinates;
  final String addressName;

  LocationResult(this.coordinates, this.addressName);
}

class LocationPickerPage extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerPage({
    super.key, 
    required this.initialLocation
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // 💡 State Baru
  LatLng? _pickedLocation;
  String _locationName = "Memilih Lokasi..."; // Sekarang bisa diubah
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController(); // 💡 Controller Pencarian
  bool _isLoadingName = false; // 💡 Untuk indikator loading nama lokasi

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    // Panggil reverse geocode awal untuk mengisi nama lokasi awal
    _reverseGeocode(_pickedLocation!); 
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 💡 FUNGSI BARU: Mendapatkan nama alamat (Reverse Geocoding)
  void _reverseGeocode(LatLng location) async {
    setState(() {
      _isLoadingName = true;
      _locationName = "Mengambil nama lokasi...";
    });
    
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        // Menggunakan nama, jalan, atau sub-lokalitas sebagai nama alamat
        final String address = 
            place.street != null && place.street!.isNotEmpty ? place.street! : place.name ?? place.subLocality ?? "Lokasi Tidak Dikenal";

        setState(() { 
          _locationName = address;
          // Set text field pencarian juga agar sinkron
          _searchController.text = address; 
        });
      } else {
        setState(() { _locationName = "Nama Lokasi Tidak Ditemukan"; });
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
      setState(() { _locationName = "Gagal Mengambil Nama Lokasi"; });
    } finally {
      setState(() { _isLoadingName = false; });
    }
  }

  // 💡 FUNGSI BARU: Mencari koordinat dari alamat (Forward Geocoding)
  void _searchLocation(String address) async {
    if (address.trim().isEmpty) return;

    try {
      final List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final Location loc = locations.first;
        final newLatLng = LatLng(loc.latitude, loc.longitude);
        
        // Pindahkan kamera peta ke lokasi yang baru
        _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
        
        // Update _pickedLocation untuk ditampilkan di tengah
        setState(() {
          _pickedLocation = newLatLng;
          // Setelah pindah, nama lokasi akan di-update oleh onCameraIdle
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alamat tidak ditemukan!")),
        );
      }
    } catch (e) {
      debugPrint("Error forward geocoding: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mencari lokasi: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi Event"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_pickedLocation != null) {
                // Mengembalikan hasil ke halaman Add Event
                Navigator.pop(
                  context, 
                  // Pastikan mengembalikan _locationName yang sudah di-geocode
                  LocationResult(_pickedLocation!, _locationName) 
                );
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation,
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller; // Simpan controller
              // Panggil reverse geocode awal untuk mengisi nama lokasi awal
              _reverseGeocode(_pickedLocation!); 
            },
            // Ketika peta bergerak, update lokasi tengah
            onCameraMove: (position) {
              _pickedLocation = position.target;
            },
            // 💡 Ketika peta berhenti bergerak, lakukan Reverse Geocoding
            onCameraIdle: () {
              if (_pickedLocation != null) {
                _reverseGeocode(_pickedLocation!);
              }
            },
            // Hapus Marker bawaan (hanya gunakan Crosshair)
            markers: const {}, 
            // Marker hanya akan ditampilkan di tengah layar melalui Crosshair
            // markers: _pickedLocation != null ? {
            //   Marker(
            //     markerId: const MarkerId("picked_location"),
            //     position: _pickedLocation!,
            //   ),
            // } : {},
          ),
          
          // Crosshair / Pin di tengah layar
          const Center(
            child: Icon(
              Icons.location_on, 
              size: 40, 
              color: Colors.red,
            ),
          ),

          // 💡 WIDGET BARU: Search Bar di atas
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Alamat atau Tempat...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _searchLocation(_searchController.text);
                    },
                  ),
                ),
                onSubmitted: (value) {
                  _searchLocation(value);
                },
              ),
            ),
          ),

          // Tampilkan nama lokasi yang dipilih
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: _isLoadingName 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text("Memuat alamat...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Text(
                    _locationName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
            ),
          )
        ],
      ),
    );
  }
}