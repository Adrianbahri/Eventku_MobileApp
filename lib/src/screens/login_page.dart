import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../Utils/app_colors.dart';
import '../Widget/custom_form_field.dart';

// ===========================================
// 1. HALAMAN UTAMA LOGIN (StatelessWidget)
// ===========================================
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
                      Center(
                        child:
                          // Pastikan path ini benar
                          Image.asset('assets/image/animLogo.gif', width: 300), 
                      ),
                      const SizedBox(height: 40),

                      // JUDUL
                      const Text(
                        'Log In to Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // FORM LOGIN
                      const _LoginForm(),
                      const SizedBox(height: 30),

                      // FOOTER: NAVIGASI KE REGISTER (MENGGANTIKAN SOCIAL LOGIN)
                      const _Footer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ===========================================
// 2. FORM LOGIN (StatefulWidget)
// ===========================================
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!mounted) return;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in email and password'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Ganti dengan nama route dashboard Anda yang benar jika berbeda
        Navigator.pushReplacementNamed(context, '/dashboard'); 
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later.';
      } else {
        message = "Login failed: ${e.message}";
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

  Future<void> _sendPasswordResetLink() async {
    if (!mounted) return;
    
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent! Check your email.'), backgroundColor: AppColors.success),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = e.code == 'user-not-found' ? 'No user found with that email.' : 'Failed to send reset link.';
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field menggunakan CustomFormField
        CustomFormField(
          label: 'Email address', 
          controller: _emailController, 
          keyboardType: TextInputType.emailAddress,
          hintText: 'enter your email address',
        ),
        
        const SizedBox(height: 20),

        // Password Field menggunakan CustomFormField
        CustomFormField(
          label: 'Password',
          controller: _passwordController,
          isPassword: true, 
          hintText: 'Password',
        ),
        
        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _sendPasswordResetLink,
            child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ),
        ),

        const SizedBox(height: 10),

        // Tombol Login
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: AppColors.textLight, strokeWidth: 2),
                )
              : const Text('Log In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ===========================================
// 3. WIDGET PENDUKUNG: Footer Navigasi (Register)
// ===========================================
// Menggantikan _SocialLogin dan _Footer lama
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1.0, 
          width: double.infinity,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 40),
        
        // Tautan Register
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
            GestureDetector(
              onTap: () {
                // Ganti dengan nama route register Anda yang benar jika berbeda
                Navigator.pushReplacementNamed(context, '/register'); 
              },
              child: const Text(
                "Register",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}