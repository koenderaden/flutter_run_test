import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';

class WalkingSession extends StatefulWidget {
  final String sessionId;
  final String userId;

  const WalkingSession({super.key, required this.sessionId, required this.userId});

  @override
  State<WalkingSession> createState() => _WalkingSessionState();
}

class _WalkingSessionState extends State<WalkingSession> {
  late Stream<StepCount> _stepCountStream;
  int _steps = 0;
  int? _lastStepCount;
  String _status = 'Waiting for step counter...';
  bool sessionExists = false;
  int stepGoal = 5000;
  bool goalSet = false;
  final TextEditingController goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();
    fetchSessionData();
  }

  void requestPermission() async {
    if (await Permission.activityRecognition.request().isGranted) {
      initPedometer();
    } else {
      setState(() {
        _status = 'Geen permissie!';
      });
    }
  }

  void initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen((StepCount event) {
      if (mounted) {
        setState(() {
          if (_lastStepCount == null) {
            _lastStepCount = event.steps;
          }
          if (event.steps > _lastStepCount!) {
            _steps += event.steps - _lastStepCount!;
          }
          _lastStepCount = event.steps;
          _status = 'Teller werkt';

          updateStepsInFirestore();
        });
      }
    }, onError: (error) {
      setState(() {
        _status = 'Error: $error';
      });
    });
  }

  void updateStepsInFirestore() {
    FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).update({
      widget.userId == 'host' ? 'hostSteps' : 'buddySteps': _steps,
    });
  }

  Future<void> fetchSessionData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('walking_sessions')
          .doc(widget.sessionId)
          .get();

      if (!doc.exists || doc.data() == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fout: Sessie niet gevonden!")),
        );
        return;
      }

      setState(() {
        sessionExists = true;
      });
    } catch (e) {
      print("Fout bij ophalen van sessiegegevens: $e");
    }
  }

  void setStepGoal() {
    int? newGoal = int.tryParse(goalController.text);
    if (newGoal != null && newGoal > 0) {
      setState(() {
        stepGoal = newGoal;
        goalSet = true;
        goalController.clear();
      });
    }
  }

  void openGoalSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Stapdoel Instellen"),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Voer een nieuw stapdoel in",
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setStepGoal();
                Navigator.pop(context);
              },
              child: Text("Opslaan"),
            ),
          ],
        );
      },
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusWidget(),
            const SizedBox(height: 30),
            _goalDisplay(),
            const SizedBox(height: 30),
            stepsDisplay(),
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

  Widget _goalDisplay() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Stapdoel: $stepGoal stappen',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: openGoalSettings,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
              child: Text("Stapdoel Wijzigen"),
            ),
          ],
        ),
      );

  Widget stepsDisplay() => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var data = snapshot.data!.data() as Map<String, dynamic>;
          int hostSteps = data['hostSteps'] ?? 0;
          int buddySteps = data['buddySteps'] ?? 0;
          int totalSteps = hostSteps + buddySteps;

          double progress = (totalSteps / stepGoal).clamp(0.0, 1.0);
          int stepsRemaining = stepGoal - totalSteps;
          stepsRemaining = stepsRemaining < 0 ? 0 : stepsRemaining;

          Color progressColor;
          if (progress >= 0.8) {
            progressColor = Colors.red;
          } else if (progress >= 0.5) {
            progressColor = Colors.orange;
          } else {
            progressColor = AppColors.accentGreen;
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stepCard("Jouw Stappen", hostSteps, Icons.directions_walk),
                  _stepCard("Buddy Stappen", buddySteps, Icons.group),
                ],
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[800],
                color: progressColor,
              ),
              const SizedBox(height: 10),
              Text(
                '$totalSteps / $stepGoal stappen gezet',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          );
        },
      );

  Widget _stepCard(String title, int steps, IconData icon) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentGreen, size: 30),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('$steps', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
