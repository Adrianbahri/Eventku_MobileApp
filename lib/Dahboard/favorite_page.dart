import 'package:flutter/material.dart';
import '../Fungsi/favorite_helper.dart';
import '../Fungsi/app_colors.dart'; 

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<String> favoriteIds = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final favs = await FavoriteHelper.getFavorites();
    setState(() {
      favoriteIds = favs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorit Saya"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      body: favoriteIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 90, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum ada event favorit.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favoriteIds.length,
              itemBuilder: (context, index) {
                final id = favoriteIds[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text("ID Event: $id"),
                    subtitle: const Text("Event yang kamu favoritkan"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () async {
                        await FavoriteHelper.toggleFavorite(id);
                        loadFavorites();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
