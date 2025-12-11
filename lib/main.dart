import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/screens/login_page.dart';
import 'src/screens/register_page.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'src/screens/dashboard_page.dart';
import '/src/Widget/auth_wrapper.dart';
import '/src/Utils/firebase_options.dart';
import 'src/utils/api_key_loader.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ApiKeyLoader().loadKeys();
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