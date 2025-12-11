// File: lib/utils/api_key_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ApiKeyLoader {
  // Singleton pattern (sudah benar)
  static final ApiKeyLoader _instance = ApiKeyLoader._internal();
  factory ApiKeyLoader() => _instance;
  ApiKeyLoader._internal();

  // Variabel untuk menyimpan kunci
  String _googleMapsApiKey = '';
  
  // Getter publik
  String get googleMapsApiKey => _googleMapsApiKey;

  // Metode untuk memuat file dari assets
  Future<void> loadKeys() async {
    try {
      // 1. Muat konten file key.json
      // 🔥 KOREKSI UTAMA: Mengubah 'keys.json' menjadi 'key.json'
      final String jsonString = await rootBundle.loadString('assets/key.json'); 
      
      // 2. Decode JSON
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      // 3. Simpan kunci ke variabel instance
      // Pastikan nilai yang diambil di-cast ke String dan diberikan nilai default jika null/kosong
      final loadedKey = jsonMap['googleMapsApiKey'];
      
      if (loadedKey == null || loadedKey is! String || loadedKey.isEmpty) {
        throw Exception("API Key 'googleMapsApiKey' is missing or invalid in keys.json");
      }
      
      _googleMapsApiKey = loadedKey;
      
      print("API Key loaded successfully.");
      
    } catch (e) {
      // Lebih jelas menunjukkan file mana yang bermasalah
      print("FATAL ERROR: Failed to load API keys from assets/key.json: $e"); 
      // Jika terjadi kesalahan serius, Anda dapat memilih untuk melempar ulang
      // throw e; 
    }
  }
}