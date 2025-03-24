import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/running.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: AppColors.background.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔁 Hier vervangen we de tekst door het logo
                Image.asset(
                  'assets/images/fitquest_logo.png',
                  height: 100,
                ),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Already our user?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Continue with your account >',
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
