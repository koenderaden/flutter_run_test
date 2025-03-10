import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user.dart';

class WalkingSession extends StatefulWidget {
  final User? friend;
  final String sessionId;
  final User user;
  const WalkingSession({super.key, this.friend, required this.sessionId, required this.user});

  @override
  State<WalkingSession> createState() => _WalkingSessionState();
}

class _WalkingSessionState extends State<WalkingSession> {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  int? _lastStepCount;
  String _status = 'Waiting for step counter...';
  Timer? _friendStepsSimulator;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _listenToFirestore();
  }

  void initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted) {
      try {
        _stepCountStream = Pedometer.stepCountStream;
        _stepCountStream.listen(
          (StepCount event) {
            if (mounted) {
              setState(() {
                if (_lastStepCount == null) {
                  _lastStepCount = event.steps;
                }
                
                if (event.steps > _lastStepCount!) {
                  _steps += event.steps - _lastStepCount!;
                  _updateStepsInFirestore();
                }
                _lastStepCount = event.steps;
                _status = 'Counter working';
              });
            }
          },
          onError: (error) {
            setState(() {
              _status = 'Error: $error';
            });
          },
        );
      } catch (e) {
        setState(() {
          _status = 'Error: $e';
        });
      }
    } else {
      setState(() {
        _status = 'No permission';
      });
    }
  }

  void _updateStepsInFirestore() {
    FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).update({
      'users.${widget.user.id}.steps': _steps,
    });
  }

  Stream<DocumentSnapshot> _listenToFirestore() {
    return FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).snapshots();
  }

  void _inviteFriend(String friendId) {
    FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).update({
      'users.$friendId': {'steps': 0},
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Walking Together', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  TextEditingController friendController = TextEditingController();
                  return AlertDialog(
                    title: const Text("Invite a Friend"),
                    content: TextField(
                      controller: friendController,
                      decoration: const InputDecoration(hintText: "Enter Friend ID"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          _inviteFriend(friendController.text);
                          Navigator.pop(context);
                        },
                        child: const Text("Invite"),
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _listenToFirestore(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          int friendSteps = data?['users'][widget.friend?.id]['steps'] ?? 0;
          int totalSteps = _steps + friendSteps;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STATUS: $_status', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 30),
                Text('MY STEPS: $_steps', style: const TextStyle(color: Colors.white, fontSize: 24)),
                const SizedBox(height: 30),
                Text('FRIEND STEPS: $friendSteps', style: const TextStyle(color: Colors.white, fontSize: 24)),
                const SizedBox(height: 30),
                Text('TOTAL STEPS: $totalSteps', style: const TextStyle(color: Colors.white, fontSize: 24)),
                const SizedBox(height: 30),
                const Text('GOAL: 1000 STEPS', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: totalSteps / 1000,
                  backgroundColor: Colors.grey,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}