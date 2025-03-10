import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../models/user.dart';
import '../utils/app_colors.dart';

class WalkingSession extends StatefulWidget {
  final User? friend;
  const WalkingSession({super.key, this.friend});

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
    if (widget.friend != null) {
      _startFriendSimulation();
    }
  }

  void _startFriendSimulation() {
    _friendStepsSimulator = Timer.periodic(
      const Duration(seconds: 2), 
      (timer) {
        if (mounted && widget.friend != null) {
          setState(() {
            widget.friend!.steps += 2;
          });
        }
      }
    );
  }

  @override
  void dispose() {
    _friendStepsSimulator?.cancel();
    super.dispose();
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
                  _steps += 1;
                }
                _lastStepCount = event.steps;
                _status = 'Counter working';
                
                print('Event steps: ${event.steps}, Last count: $_lastStepCount, Total steps: $_steps');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: Text(
          widget.friend == null ? 'My Steps' : 'Walking Together',
          style: const TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STATUS: $_status',
              style: const TextStyle(color: AppColors.textWhite),
            ),
            const SizedBox(height: 30),
            Text(
              'MY STEPS: $_steps',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 24,
              ),
            ),
            if (widget.friend != null) ...[
              const SizedBox(height: 30),
              Text(
                'FRIEND STEPS: ${widget.friend!.steps}',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                ),
              ),
            ],
            const SizedBox(height: 30),
            const Text(
              'GOAL: 1000 STEPS',
              style: TextStyle(color: AppColors.textWhite),
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: _steps / 1000,
              backgroundColor: Colors.grey,
              color: AppColors.accentGreen,
            ),
          ],
        ),
      ),
    );
  }
}