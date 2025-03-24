import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/start_screen.dart';
import 'utils/app_colors.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Step Counter',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Helvetica',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentBlue),
      ),
      home: const StartScreen(),
    );
  }
}
