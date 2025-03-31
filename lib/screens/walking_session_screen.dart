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
  String _status = 'Wachten op stappenteller...';
  int stepGoal = 5000;
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
        _status = 'Fout: $error';
      });
    });
  }

  void updateStepsInFirestore() {
    FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).update({
      widget.userId == 'host' ? 'hostSteps' : 'buddySteps': _steps,
    });
  }

  Future<void> fetchSessionData() async {
    FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).get();
  }

  void setStepGoal() {
    int? newGoal = int.tryParse(goalController.text);
    if (newGoal != null && newGoal > 0) {
      setState(() {
        stepGoal = newGoal;
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // MAP
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset(
                'assets/images/map.png',
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // SCROLLBARE CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      stepsDisplay(),
                      const SizedBox(height: 20),
                      _goalDisplay(),
                      const SizedBox(height: 10),
                      _statusWidget(),
                      const SizedBox(height: 30),

                      // CONTROLS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _circleButton(Icons.timer, Colors.grey.shade800),
                          _circleButton(Icons.pause, AppColors.accentGreen),
                          _circleButton(Icons.stop, Colors.grey.shade800),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP PROGRESS

  Widget stepsDisplay() => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var data = snapshot.data!.data() as Map<String, dynamic>;
          int hostSteps = data['hostSteps'] ?? 0;
          int buddySteps = data['buddySteps'] ?? 0;
          int totalSteps = hostSteps + buddySteps;
          double progress = (totalSteps / stepGoal).clamp(0.0, 1.0);

          Color progressColor = progress >= 0.8
              ? Colors.red
              : progress >= 0.5
                  ? Colors.orange
                  : AppColors.accentGreen;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stepCount("Jij", hostSteps, Icons.person),
                  _stepCount("Buddy", buddySteps, Icons.person_outline),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[800],
                color: progressColor,
              ),
              const SizedBox(height: 8),
              Text(
                '$totalSteps / $stepGoal stappen gezet',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          );
        },
      );

  Widget _stepCount(String title, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentGreen, size: 28),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
        Text('$count', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // STAPDOEL

  Widget _goalDisplay() => Column(
        children: [
          Text(
            'Stapdoel: $stepGoal stappen',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: openGoalSettings,
            child: Text("Stapdoel wijzigen", style: TextStyle(color: AppColors.accentGreen)),
          ),
        ],
      );

  // STATUS

  Widget _statusWidget() => Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accentGreen, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'STATUS: $_status',
              style: TextStyle(color: AppColors.textWhite, fontSize: 14),
            ),
          ),
        ],
      );

  // KNOPPEN

  Widget _circleButton(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textWhite, size: 28),
    );
  }
}
