import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // DIPERLUKAN
import 'dart:async'; // DIPERLUKAN

// --- 1. HALAMAN UTAMA (StatelessWidget) ---
class LoginPage extends StatelessWidget {
 const LoginPage({super.key});

 @override
 Widget build(BuildContext context) {
  const gradientColors = [
   Color.fromARGB(255, 236, 207, 232),
   Color.fromARGB(255, 239, 239, 239),
  ];
  // Warna Magenta/Pink utama
  const primaryColor = Color.fromRGBO(232, 0, 168, 1);

  return Scaffold(
   // Tidak perlu backgroundColor: Colors.transparent jika menggunakan Container di body
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
        // Ini memastikan SingleChildScrollView mengisi seluruh tinggi layar jika kontennya pendek
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
         constraints: BoxConstraints(minHeight: constraints.maxHeight),
         child: Padding(
          padding: const EdgeInsets.symmetric(
           horizontal: 24.0,
           vertical: 20.0,
          ),
          child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
            const SizedBox(height: 20),

            // LOGO
            Image.asset(
             'assets/image/primarylogo.png', // Pastikan path ini benar
             width: 200,
             height: 100,
            ),

            const SizedBox(height: 40),

            // JUDUL LOGIN (Diubah agar lebih sesuai konteks Login)
            const Text(
             'Log In to Your Account', // Teks awal: 'create an account'
             textAlign: TextAlign.center,
             style: TextStyle(
              fontSize: 22, // Ukuran diperbesar agar lebih menonjol
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C4C4C),
             ),
            ),

            const SizedBox(height: 30),

            // FORM LOGIN
            _LoginForm(primaryColor: primaryColor),

            const SizedBox(height: 30),

            // SOCIAL LOGIN (Dihapus komentar)
            SocialLogin(primaryColor: primaryColor),

            const SizedBox(height: 40),

            // FOOTER: NAVIGASI KE REGISTER
            Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
              const Text(
               "Don't have an account? ",
               style: TextStyle(color: Colors.grey),
              ),
              GestureDetector(
               onTap: () {
                // Asumsi rute '/register' telah didefinisikan di MaterialApp
                Navigator.pushNamed(context, '/register');
               },
               child: Text(
                "Register",
                style: TextStyle(
                 color: primaryColor,
                 fontWeight: FontWeight.bold,
                ),
               ),
              ),
             ],
            ),
           ],
          ),
         ),
        ),
       );
      },
     ),
    ),
   ),
  );
 }
}

// --- 2. FORM LOGIN (StatefulWidget) ---
class _LoginForm extends StatefulWidget {
 final Color primaryColor;
 const _LoginForm({required this.primaryColor});

 @override
 State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
 final _emailController = TextEditingController();
 final _passwordController = TextEditingController();

 bool _isObscure = true;
 bool _isLoading = false; 

 // Fungsi Login ke Firebase
 Future<void> _handleLogin() async {
  // Validasi input kosong
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please fill in email and password'), backgroundColor: Colors.orange),
   );
   return;
  }

  setState(() {
   _isLoading = true;
  });

  try {
   // Proses Login Firebase
   await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
   );

   // Jika sukses, pindah ke dashboard
   if (mounted) {
    // Asumsi rute '/dashboard' telah didefinisikan
    Navigator.pushReplacementNamed(context, '/dashboard');
   }
  } on FirebaseAuthException catch (e) {
   // Menangani Error 
   String message = "An unknown error occurred. Try again.";
   if (e.code == 'user-not-found') {
    message = 'No user found for that email.';
   } else if (e.code == 'wrong-password') {
    message = 'Wrong password provided.';
   } else if (e.code == 'invalid-email') {
    message = 'The email address is badly formatted.';
   } else if (e.code == 'too-many-requests') {
    message = 'Too many attempts. Try again later.';
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
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  return Column(
   crossAxisAlignment: CrossAxisAlignment.stretch,
   children: [
    // Email Field
    const Text(
     'Email address',
     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF4C4C4C)),
    ),
    const SizedBox(height: 8),
    TextFormField(
     controller: _emailController, 
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

    // Password Field
    const Text(
     'Password',
     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF4C4C4C)),
    ),
    const SizedBox(height: 8),
    TextFormField(
     controller: _passwordController, 
     obscureText: _isObscure,
     decoration: InputDecoration(
      hintText: 'Password',
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

    // Forgot Password
    Align(
     alignment: Alignment.centerRight,
     child: TextButton(
      onPressed: () async {
       final email = _emailController.text.trim();

       if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: Colors.orange,
         ),
        );
        return;
       }

       setState(() {
        _isLoading = true; 
       });

       try {
        // Kirim Email Reset Password
        await FirebaseAuth.instance.sendPasswordResetEmail(
         email: email,
        );

        if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
           content: Text('Password reset link sent! Check your email.'),
           backgroundColor: Colors.green,
          ),
         );
        }
       } on FirebaseAuthException catch (e) {
        String message = 'Failed to send reset link.';
        if (e.code == 'user-not-found') {
         message = 'No user found with that email.';
        }
        if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
           content: Text(message),
           backgroundColor: Colors.red,
          ),
         );
        }
       } finally {
        if (mounted) {
         setState(() {
          _isLoading = false;
         });
        }
       }
      },
      child: Text(
       'forgot password',
       style: TextStyle(color: widget.primaryColor, fontSize: 14),
      ),
     ),
    ),

    const SizedBox(height: 10),

    // Tombol Login
    ElevatedButton(
     onPressed: _isLoading
       ? null
       : _handleLogin, 
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
         child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
         ),
        )
       : const Text(
         'Log In',
         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
    ),
   ],
  );
 }
}

// ------------------------------------------
// --- 3. WIDGET PENDUKUNG: Social Login ---
// ------------------------------------------
// ==========================================
// 3. WIDGET PENDUKUNG: Social Login & Footer
// ==========================================
class SocialLogin extends StatefulWidget {
 final Color primaryColor;
 const SocialLogin({super.key, required this.primaryColor});

 @override
 State<SocialLogin> createState() => _SocialLoginState();
}

class _SocialLoginState extends State<SocialLogin> {
 final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
 StreamSubscription<GoogleSignInAuthenticationEvent>? _authStream;

 @override
 void initState() {
super.initState();

_authStream = _googleSignIn.authenticationEvents.listen(
 _handleGoogleAuthEvent,
 onError: (error) {
if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Google Sign In Error: $error'), backgroundColor: Colors.red),
 );
}
 },
);
 }

 @override
 void dispose() {
_authStream?.cancel();
super.dispose();
 }

 Future<void> _handleGoogleAuthEvent(GoogleSignInAuthenticationEvent event) async {
// HANYA MENANGANI EVENT SIGN IN
if (event case GoogleSignInAuthenticationEventSignIn(user: final user)) {
 try {
final GoogleSignInAuthentication googleAuth = user.authentication;

// Hapus accessToken karena tidak diperlukan dan menyebabkan error
final AuthCredential credential = GoogleAuthProvider.credential(
 idToken: googleAuth.idToken, 
 // accessToken: googleAuth.accessToken, <--- BARIS INI DIHAPUS
);

await FirebaseAuth.instance.signInWithCredential(credential);

if (mounted) {
 Navigator.pushReplacementNamed(context, '/dashboard');
}
 } on FirebaseAuthException catch (e) {
if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Firebase Error: ${e.message}'), backgroundColor: Colors.red),
 );
 _googleSignIn.signOut();
}
 }
} else if (event case GoogleSignInAuthenticationEventSignOut()) {
 // Logika jika Google SignOut terjadi
}
 }

 Future<void> _triggerSignIn() async {
try {
 await _googleSignIn.authenticate();
} catch (error) {
 print("Gagal membuka popup Google: $error");
}
 }

 @override
 Widget build(BuildContext context) {
return Column(
 children: [
const Text('Or continue with', style: TextStyle(color: Colors.grey)),
const SizedBox(height: 20),

GestureDetector(
 onTap: _triggerSignIn, 
 child: Container(
padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(30),
 border: Border.all(color: Colors.grey.shade300, width: 1.5),
 boxShadow: [
BoxShadow(
 color: Colors.grey.withOpacity(0.1),
 blurRadius: 5,
 offset: const Offset(0, 2),
)
 ],
),
child: Row(
 mainAxisSize: MainAxisSize.min,
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
Image.asset(
 'assets/image/Google_Favicon_2025.png',
 width: 24,
 height: 24,
 errorBuilder: (context, error, stackTrace) => 
const Icon(Icons.error, color: Colors.red),
),
const SizedBox(width: 12),
const Text(
 'Google',
 style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.w600,
color: Colors.black87,
 ),
)
 ],
),
 ),
)
 ],
);
 }
}