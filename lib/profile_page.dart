import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

// PASTIKAN PATH INI BENAR DI PROYEK ANDA
import 'event_model.dart'; 
import 'detail_page.dart'; 

// --- 1. KONSTANTA WARNA ---
class AppColors {
  static const primary = Color.fromRGBO(232, 0, 168, 1);
  static const background = Color(0xFFF5F5F5);
  static const textDark = Colors.black87;
  static const inputBg = Color(0xFFF9F9F9);
}

// --- 2. HALAMAN UTAMA PROFIL ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  // Controller hanya untuk nama, karena email dihapus
  final TextEditingController _nameController = TextEditingController();

  // State untuk Loading dan Foto Profil
  bool _isLoading = false;
  Uint8List? _newImageBytes; // Untuk menyimpan bytes foto yang dipilih

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data pengguna saat ini
    _nameController.text = currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- LOGIKA FIREBASE AUTH & STORAGE ---

  // 1. Pilih dan Upload Foto Profil
  Future<void> _pickAndUploadProfileImage() async {
    if (currentUser == null) return;
    
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        imageQuality: 70,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _newImageBytes = bytes;
          _isLoading = true; // Mulai loading saat upload
        });

        // Upload ke Firebase Storage
        String fileName = 'profiles/${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        UploadTask uploadTask = storageRef.putData(bytes, metadata);
        
        TaskSnapshot snapshot = await uploadTask;
        String photoUrl = await snapshot.ref.getDownloadURL();

        // Update photoURL di Firebase Auth
        await currentUser!.updatePhotoURL(photoUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Foto profil berhasil diubah!")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error upload image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunggah foto: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // 2. Logika Ganti Nama (Display Name)
  Future<void> _updateUserName() async {
    if (currentUser == null || _nameController.text.isEmpty) return;
    if (_nameController.text == currentUser!.displayName) return;

    setState(() => _isLoading = true);
    try {
      await currentUser!.updateDisplayName(_nameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama berhasil diperbarui!"))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memperbarui nama: $e"))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 Logika Ganti Email Dihapus.
  
  // 3. Logika Ganti Sandi (Mengirim Reset Link)
  Future<void> _sendPasswordResetLink() async {
    if (currentUser == null || currentUser!.email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email tidak ditemukan.")),
          );
        }
        return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Link ganti sandi telah dikirim ke email Anda!"))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim link: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. Logika Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Mengarahkan ke halaman login/home (Anda perlu menyesuaikan rute Anda)
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda telah Log Out.")),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Saya")),
        body: const Center(child: Text("Anda harus login untuk melihat profil.")),
      );
    }

    currentUser!.reload(); 
    final updatedUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // --- FOTO PROFIL & INFO DASAR ---
              _buildProfileHeader(updatedUser),
              const SizedBox(height: 30),

              // --- FITUR EDIT AKUN ---
              const Text(
                "Pengaturan Akun",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 15),

              _buildEditForm(),
              const SizedBox(height: 30),
              
              // --- LIST EVENT PRIBADI ---
              const Text(
                "Event yang Anda Upload",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 15),
              _UserEventList(currentUserId: updatedUser!.uid),
              
              const SizedBox(height: 40),

              // --- OPSI LOGOUT ---
              _LogoutButton(onLogout: _logout),
            ],
          ),
          // Indikator Loading Global
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  // WIDGETS HELPER

  Widget _buildProfileHeader(User? user) {
    // Tentukan sumber gambar: bytes baru > photoURL > fallback icon
    Widget profileImage;
    if (_newImageBytes != null) {
      profileImage = Image.memory(_newImageBytes!, fit: BoxFit.cover);
    } else if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      profileImage = Image.network(
        user.photoURL!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.white),
      );
    } else {
      profileImage = const Icon(Icons.person, size: 50, color: Colors.white);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickAndUploadProfileImage,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.5),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    profileImage,
                    const Icon(Icons.camera_alt, color: Colors.white70, size: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          user?.displayName ?? 'User',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        Text(
          user?.email ?? 'Email tidak tersedia',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    // Form kini hanya berisi edit nama dan ganti sandi
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EDIT NAMA
          _buildTextFieldWithButton(
            controller: _nameController,
            label: "Nama Pengguna",
            icon: Icons.person_outline,
            onPressed: _updateUserName,
            buttonText: "Update Nama",
          ),
          const SizedBox(height: 15),
          
          // GANTI SANDI
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.vpn_key_outlined, size: 20),
              label: const Text("Ganti Sandi (Kirim Link Reset)"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _sendPasswordResetLink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithButton({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required String buttonText,
    bool readOnly = false,
    String? helperText,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                readOnly: readOnly,
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              if (helperText != null) 
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(helperText, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48, // Sesuaikan tinggi tombol
          child: ElevatedButton(
            onPressed: readOnly ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}


// ------------------------------------------
// --- WIDGET LIST EVENT PENGGUNA (DENGAN LOGIKA HAPUS STORAGE) ---
// ------------------------------------------

class _UserEventList extends StatelessWidget {
  final String currentUserId;
  const _UserEventList({required this.currentUserId});

  // Menampilkan dialog konfirmasi sebelum menghapus
  Future<bool> _showDeleteConfirmationDialog(BuildContext context, String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event'),
        content: Text('Apakah Anda yakin ingin menghapus event "$title"? Event dan gambarnya akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  // Fungsi untuk menghapus event dari Firestore DAN Firebase Storage
  Future<void> _deleteEvent(BuildContext context, String eventId, String eventTitle) async {
    final shouldDelete = await _showDeleteConfirmationDialog(context, eventTitle);

    if (!shouldDelete) return;

    try {
      // 1. Ambil data event untuk mendapatkan URL gambar
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
      final eventData = eventDoc.data();
      final imageUrl = eventData?['imagePath'] as String?;

      // 2. Hapus dokumen dari Firestore
      await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
      
      // 3. Hapus gambar dari Firebase Storage (jika URL gambar valid)
      if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
        try {
          // Dapatkan reference storage dari URL
          final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
          await storageRef.delete();
          debugPrint("Gambar berhasil dihapus dari Storage: $imageUrl");
        } catch (e) {
          debugPrint("Peringatan: Gagal menghapus gambar dari Storage: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event berhasil dihapus.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus event: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: currentUserId) 
        .orderBy('timestamp', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          if (snapshot.error.toString().contains('failed-precondition')) {
            return const Text(
              "Error Firestore: Kueri memerlukan indeks gabungan. Silakan buat di Firebase Console.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            );
          }
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Anda belum mengupload event apa pun."),
          ));
        }

        final List<EventModel> userEvents = snapshot.data!.docs.map((doc) {
          return EventModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userEvents.length,
          itemBuilder: (context, index) {
            final event = userEvents[index];
            final isNetworkImageValid = event.imagePath.startsWith('http');

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isNetworkImageValid && event.imagePath.isNotEmpty
                    ? Image.network(
                        event.imagePath, 
                        width: 50, height: 50, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.broken_image, color: Colors.grey, size: 24),
                      )
                    : const Icon(Icons.image_not_supported, color: Colors.grey, size: 24),
                ),
                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${event.date} - ${event.location}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEvent(context, event.id, event.title), 
                ),
                onTap: () {
                  // Navigasi ke DetailPage
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(event: event)));
                },
              ),
            );
          },
        );
      },
    );
  }
}

// --- 5. WIDGET TOMBOL LOGOUT ---
class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text("Log Out"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onLogout,
        ),
      ),
    );
  }
}