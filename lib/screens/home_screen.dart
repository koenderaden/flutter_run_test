import 'package:flutter/material.dart';
import 'walking_session_screen.dart';
import '../models/user.dart';
import '../utils/user_database.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Test Screen Flutter Run App',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Basic Tests:', style: TextStyle(fontSize: 16, color: AppColors.textWhite)),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.textWhite,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalkingSession(),
                ),
              ),
              child: const Text('Test Basic Counter'),
            ),
            const SizedBox(height: 16),
            const Text('Friend Tests:', style: TextStyle(fontSize: 16, color: AppColors.textWhite)),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.textWhite,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WalkingSession(),
                ),
              ),
              child: const Text('Test With Friend'),
            ),
          ],
        ),
      ),
    );
  }
}
