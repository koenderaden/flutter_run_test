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
      },
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
        elevation: 0,
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: Image.asset(
          'assets/images/fitquest_logo.png',
          height: 40,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusWidget(),
            const SizedBox(height: 30),
            _stepsInfo(),
            if (widget.friend != null) _friendStepsInfo(),
            const SizedBox(height: 30),
            _goalProgress(),
          ],
        ),
      ),
    );
  }

  Widget _statusWidget() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.accentGreen, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'STATUS: $_status',
                style: TextStyle(color: AppColors.textWhite, fontSize: 16),
              ),
            ),
          ],
        ),
      );

  Widget _stepsInfo() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Jouw Stappen',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$_steps',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _friendStepsInfo() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Vriend Stappen',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.friend!.steps}',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _goalProgress() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doel: 1000 Stappen',
            style: TextStyle(color: AppColors.textWhite, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.75 * (_steps / 1000),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_steps / 1000',
              style: TextStyle(color: AppColors.textWhite, fontSize: 14),
            ),
          ),
        ],
      );
}
