import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  LatLng? _pickedLocation;
  String _locationName = "Memilih Lokasi...";

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
  }

  // Fungsi untuk mendapatkan nama alamat (opsional, perlu package geocoding)
  // Anda bisa menggunakan Geocoding API di sini.
  // void _reverseGeocode(LatLng location) async {
  //   // Implementasi Geocoding.
  //   // Contoh: final List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
  //   // setState(() { _locationName = placemarks.first.name; });
  // }

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
            // Ketika peta bergerak, update lokasi tengah
            onCameraMove: (position) {
              _pickedLocation = position.target;
              // Jika Anda menggunakan Geocoding, panggil _reverseGeocode di onCameraIdle
            },
            onMapCreated: (controller) {
              // Jika Anda ingin melakukan sesuatu saat peta dibuat
            },
            // Hanya tampilkan marker di tengah layar
            markers: _pickedLocation != null ? {
              Marker(
                markerId: const MarkerId("picked_location"),
                position: _pickedLocation!,
              ),
            } : {},
          ),
          
          // Crosshair / Pin di tengah layar
          const Center(
            child: Icon(
              Icons.location_on, 
              size: 40, 
              color: Colors.red,
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
              child: Text(
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