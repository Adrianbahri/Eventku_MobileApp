import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Fungsi/app_colors.dart';

// ===========================================
// 1. HALAMAN UTAMA REGISTER (StatelessWidget)
// ===========================================
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea( 
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOGO
                      Image.asset(
                        'assets/image/animLogo.gif',
                        width: 200,
                        height: 100,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // JUDUL
                      const Text(
                        'Create new account', 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // FORM REGISTER
                      const _RegistForm(),
                      
                      const SizedBox(height: 40),
                      
                      // FOOTER NAVIGASI KE LOGIN
                      // const _Footer(),
                    ],
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}


// ===========================================
// 2. FORM REGISTER (StatefulWidget)
// ===========================================
class _RegistForm extends StatefulWidget {
  const _RegistForm();

  @override
  State<_RegistForm> createState() => _RegistFormState();
}

class _RegistFormState extends State<_RegistForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Name, Email, and Password.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
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
      
      // 3. KIRIM EMAIL VERIFIKASI
      await userCredential.user?.sendEmailVerification(); 
      
      // 4. Jika sukses, beri notifikasi dan kembali ke Login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Success! Please check your email to verify.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman Login
      }
    } on FirebaseAuthException catch (e) {
      String message;
      
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak (min 6 characters).';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      } else {
        message = 'Registration failed: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
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
        // Name Field
        _buildInputField('Full Name', _nameController, TextInputType.name),
        
        const SizedBox(height: 20),
        
        // Email Field
        _buildInputField('Email', _emailController, TextInputType.emailAddress),
        
        const SizedBox(height: 20),
        
        // Password Field
        _buildPasswordField(),
        
        const SizedBox(height: 30),
        
        // Tombol Sign Up
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
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
                child: CircularProgressIndicator(color: AppColors.textLight, strokeWidth: 2),
              )
            : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Helper untuk TextFormField standar
  Widget _buildInputField(String label, TextEditingController controller, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: 'enter your $label',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  // Helper untuk Password Field
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _isObscure,
          decoration: InputDecoration(
            hintText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            ),
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ===========================================
// 3. WIDGET PENDUKUNG: Footer Navigasi
// ===========================================
// class _Footer extends StatelessWidget {
//   const _Footer();

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Text("Do you have an account? ", style: TextStyle(color: Colors.grey)),
//         GestureDetector(
//           onTap: () {
//             // Menggunakan pop untuk kembali ke halaman Login
//             Navigator.pop(context);
//           },
//           child: const Text(
//             "Login",
//             style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ],
//     );
//   }
// }