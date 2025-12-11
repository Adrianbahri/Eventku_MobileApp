import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_page.dart';
import 'login_page.dart';
import '../Models/event_model.dart';
import '../Utils/app_colors.dart';
import '../Utils/event_repository.dart';

// --- HALAMAN UTAMA PROFIL ---
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Logika Ganti Nama (Display Name)
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

  // Logika Ganti Sandi (Mengirim Reset Link)
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

  // Logika Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()), 
        (Route<dynamic> route) => false,
      );
      
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

    // Mendapatkan data user terbaru
    // currentUser!.reload(); // Dihapus karena reload sering memicu race condition
    final updatedUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // HEADER INFORMASI USER
              _buildUserInfoHeader(updatedUser),
              const SizedBox(height: 30),

              // PENGATURAN AKUN
              const Text(
                "Pengaturan Akun",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 15),

              _buildEditForm(),
              const SizedBox(height: 40),
              
              // LIST EVENT PRIBADI
              const Text(
                "Event yang Anda Upload",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 15),
              // Pastikan updatedUser tidak null di sini (sudah dicek di awal build)
              _UserEventList(currentUserId: updatedUser!.uid), 
              
              const SizedBox(height: 40),

              // OPSI LOGOUT
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

  // WIDGETS HELPER UNTUK KETERSTRUKTURAN (Tidak Berubah)

  Widget _buildUserInfoHeader(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 90,
          width: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.person, size: 48, color: AppColors.primary), 
          ),
        ),
        const SizedBox(height: 15),
        Text(
          user?.displayName ?? 'User',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'Email tidak tersedia',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textLight,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFieldWithButton(
            controller: _nameController,
            label: "Nama Pengguna",
            icon: Icons.person_outline,
            onPressed: _updateUserName,
            buttonText: "Update Nama",
          ),
          const SizedBox(height: 20),
          
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
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: readOnly ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(buttonText, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

// --- WIDGET LIST EVENT PRIBADI (REFECTORED) ---
class _UserEventList extends StatelessWidget {
  final String currentUserId;
  // 🆕 Instance Repository
  final EventRepository _eventRepo = EventRepository(); 

  _UserEventList({required this.currentUserId});

  Future<bool> _showDeleteConfirmationDialog(BuildContext context, String title) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Event'),
        content: Text('Apakah Anda yakin ingin menghapus event "$title"? Event akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
  }

  // 🔥 FUNGSI DELETE MENGGUNAKAN REPOSITORY
  Future<void> _deleteEvent(BuildContext context, String eventId, String eventTitle) async {
    final localContext = context; 

    final shouldDelete = await _showDeleteConfirmationDialog(localContext, eventTitle);

    if (!shouldDelete) return;

    try {
      // ✅ KOREKSI: Panggil Repository untuk menghapus data
      await _eventRepo.deleteEvent(eventId);
      
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(content: Text('Event berhasil dihapus.'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(content: Text('Gagal menghapus event: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 GANTI StreamBuilder<QuerySnapshot> dengan StreamBuilder<List<EventModel>>
    // dan panggil EventRepository
    return StreamBuilder<List<EventModel>>(
      stream: _eventRepo.getUserUploadedEventsStream(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Anda belum mengupload event apa pun."),
          ));
        }

        // Data yang diterima sudah berupa List<EventModel>
        final List<EventModel> userEvents = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userEvents.length,
          itemBuilder: (context, index) {
            final event = userEvents[index];
            final isNetworkImageValid = event.imagePath.startsWith('http');

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))], 
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: isNetworkImageValid && event.imagePath.isNotEmpty
                      ? Image.network(
                          event.imagePath, 
                          width: 55, height: 55, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                        )
                      : Container(
                          width: 55, height: 55, color: AppColors.inputBg,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                        ),
                  ),
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  subtitle: Text("${event.date} | ${event.location}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _deleteEvent(context, event.id, event.title), 
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(event: event)));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- WIDGET TOMBOL LOGOUT (Tidak Berubah) ---
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
            side: const BorderSide(color: AppColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: onLogout,
        ),
      ),
    );
  }
}