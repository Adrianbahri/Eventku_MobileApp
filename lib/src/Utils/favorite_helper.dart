import 'package:shared_preferences/shared_preferences.dart';

class FavoriteHelper {
  static const String key = "favoriteEvents";

  /// Ambil list ID event favorit dari local storage
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  /// Tambah atau hapus event dari favorit
  static Future<void> toggleFavorite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(key) ?? [];

    if (favs.contains(eventId)) {
      favs.remove(eventId); // kalau sudah ada, hapus (unfavorite)
    } else {
      favs.add(eventId); // kalau belum ada, tambahkan
    }

    await prefs.setStringList(key, favs);
  }

  /// Cek apakah sebuah event sudah difavoritkan
  static Future<bool> isFavorite(String eventId) async {
    final favs = await getFavorites();
    return favs.contains(eventId);
  }
}
