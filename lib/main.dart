import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Fungsi/firebase_options.dart';
import 'login page/login_page.dart';
import 'login page/register_page.dart';
import 'Dahboard/dashboard_page.dart';
import 'Fungsi/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const EventApp());
}

class EventApp extends StatelessWidget {
  const EventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Apps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const HomePage(),
        '/verify': (context) => const VerifyEmailPage(),
      },
    );
  }
}