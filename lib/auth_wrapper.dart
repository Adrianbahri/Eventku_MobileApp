// File: auth_wrapper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import halaman Login dan Dashboard kamu
import 'login_page.dart';
import 'dashboard_page.dart';

// File: auth_wrapper.dart
// ... (imports sama) ...

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ... (Cek Status Koneksi sama) ...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // Jika tidak ada pengguna yang login, arahkan ke Login
          return const LoginPage();
        } else {
          // Jika ada pengguna yang login:
          if (!user.emailVerified) {
            // JIKA EMAIL BELUM DIVERIFIKASI, arahkan ke halaman Verifikasi
            return const VerifyEmailPage(); // Panggil halaman verifikasi
          } else {
            // JIKA EMAIL SUDAH DIVERIFIKASI, arahkan ke Dashboard
            return const HomePage();
          }
        }
      },
    );
  }
}
