import 'package:flutter/material.dart';
import '../models/user.dart';
import 'walking_session_screen.dart';
import '../utils/user_database.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tests',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalkingSession()),
            ),
            child: const Text('Step Counter (alleen ik)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalkingSession(
                  friend: onlineUsers['emma123'],
                ),
              ),
            ),
            child: const Text('Step Counter (samen lopen)'),
          ),
        ],
      ),
    );
  }
} 