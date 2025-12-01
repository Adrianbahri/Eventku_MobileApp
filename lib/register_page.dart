import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    const gradientColors = [
      Color.fromARGB(255, 236, 207, 232),
      Color.fromARGB(255, 239, 239, 239),
    ];
    const primaryColor = Color.fromRGBO(232, 0, 168, 1); 

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            colors: gradientColors,
            radius: 1.2,
          ),
        ),        
        child: SafeArea( 
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Spacer atas
                        const SizedBox(height: 20),

                        Image.asset(
                          'assets/image/primarylogo.png',
                          width: 200,
                          height: 100,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        const Text(
                          'Create new account', 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Color(0xFF4C4C4C)),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        _RegistForm(primaryColor: primaryColor),
                        
                        const SizedBox(height: 30),
                        
                        // _SocialLogin(primaryColor: primaryColor),
                        
                        const SizedBox(height: 40),
                        
                        _Footer(primaryColor: primaryColor),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}


class _RegistForm extends StatefulWidget {
  final Color primaryColor;
  const _RegistForm({required this.primaryColor});

  @override
  State<_RegistForm> createState() => _RegistFormState();
}

class _RegistFormState extends State<_RegistForm> {
  // Controllers untuk menangkap input
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
      if (_nameController.text.isEmpty || 
          _emailController.text.isEmpty || 
          _passwordController.text.isEmpty) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill in Name, Email, and Password.'),
        backgroundColor: Colors.orange,
      ),
    );
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Buat user baru di Firebase Auth
        UserCredential userCredential = 
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Simpan "Full Name"
        await userCredential.user?.updateDisplayName(_nameController.text.trim());
        
        // 3. KIRIM EMAIL VERIFIKASI BARU
        await userCredential.user?.sendEmailVerification(); 
        
        // 4. Jika sukses, beri notifikasi dan kembali ke Login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Success! Please check your email to verify.'), // Pesan diperbarui
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman Login
        }
      } on FirebaseAuthException catch (e) {
        // --- TAMBAHKAN KODE INI ---
        String message = 'Registration failed.';
        
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is badly formatted.';
        } else if (e.code == 'operation-not-allowed') {
          message = 'Email/Password sign-in is not enabled in Firebase Console.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
  }
    @override
    void dispose() {
      // Bersihkan controller saat widget dihapus agar hemat memori
      _nameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Full Name',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController, // Sambungkan controller nama
          decoration: InputDecoration(
            hintText: 'enter your name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        
        const SizedBox(height: 20),
        
        const Text(
          'Email',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController, // Sambungkan controller email
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'enter your email',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        
        const SizedBox(height: 20),
        
        const Text(
          'Password',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: _passwordController, // Sambungkan controller password
          obscureText: _isObscure, // Menggunakan variabel state
          decoration: InputDecoration(
            hintText: 'Password',
            // Tombol Mata
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[400],
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        
        const SizedBox(height: 30),
        
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister, // Matikan tombol jika loading
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Sign Up', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
        ),
      ],
    );
  }
}


// class _SocialLogin extends StatelessWidget {
//   final Color primaryColor;
//   const _SocialLogin({required this.primaryColor});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Text('Or continue with', style: TextStyle(color: Colors.grey)),
//         const SizedBox(height: 20),
        
//         GestureDetector(
//           onTap: () {
//              // Aksi Login Google nanti
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(30),
//               border: Border.all(color: Colors.grey.shade300, width: 1.5),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   blurRadius: 5,
//                   offset: const Offset(0, 2),
//                 )
//               ]
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset(
//                   'assets/image/Google_Favicon_2025.png',
//                   width: 24,
//                   height: 24,
//                   fit: BoxFit.contain,
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Google',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87
//                   )
//                 )
//               ],
//             ),
//           ),
//         )
//       ],
//     );
//   }
// }

class _Footer extends StatelessWidget {
  final Color primaryColor;
  const _Footer({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Do you have an account? ",
          style: TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: () {
            // Menggunakan pop untuk kembali ke halaman Login (karena sebelumnya kita push dari login)
            Navigator.pop(context);
          },
          child: Text(
            "Login",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}