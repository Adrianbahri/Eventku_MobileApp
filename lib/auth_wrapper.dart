import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Pastikan import ini sesuai dengan nama file Anda
import 'login_page.dart'; 
import 'dashboard_page.dart'; // Ubah '' ke 'home_page.dart' jika file utama Anda bernama home_page.dart

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Cek Koneksi: Tampilkan Loading jika Firebase sedang memuat status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // 2. Cek User Login
        if (user == null) {
          // Jika tidak ada user login -> Ke Halaman Login
          return const LoginPage();
        } else {
          // 3. Cek Verifikasi Email
          if (!user.emailVerified) {
            // Jika user login TAPI email belum verifikasi -> Ke Halaman Verifikasi
            return const VerifyEmailPage(); 
          } else {
            // Jika user login DAN email sudah verifikasi -> Ke Home Page
            return const HomePage();
          }
        }
      },
    );
  }
}

// ==========================================================
// KELAS VERIFY EMAIL PAGE (Didefinisikan di sini agar terbaca)
// ==========================================================

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isSendingVerification = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Opsional: Kirim email otomatis saat halaman dibuka pertama kali
    // _sendVerificationEmail(); 
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _isSendingVerification = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verifikasi telah dikirim! Cek inbox/spam.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim email: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingVerification = false);
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isChecking = true);
    try {
      // Reload user untuk mendapatkan status terbaru dari Firebase
      await FirebaseAuth.instance.currentUser?.reload();
      
      final user = FirebaseAuth.instance.currentUser;
      // Jika sudah terverifikasi
      if (user != null && user.emailVerified) {
        // Tidak perlu navigasi manual, karena AuthWrapper (StreamBuilder) 
        // akan otomatis mendeteksi perubahan dan mengarahkan ke HomePage
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Email berhasil diverifikasi!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email belum terverifikasi. Silakan cek lagi.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Silakan verifikasi email Anda untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Tombol Cek Status (Manual Refresh)
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkEmailVerified,
                icon: const Icon(Icons.refresh),
                label: _isChecking 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Saya Sudah Verifikasi'),
              ),
              
              const SizedBox(height: 10),
              
              // Tombol Kirim Ulang Email
              TextButton(
                onPressed: _isSendingVerification ? null : _sendVerificationEmail,
                child: Text(_isSendingVerification ? 'Mengirim...' : 'Kirim Ulang Email Verifikasi'),
              ),
              
              const SizedBox(height: 30),
              
              // Tombol Logout (Penting agar user tidak terjebak)
              OutlinedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Logout / Ganti Akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}