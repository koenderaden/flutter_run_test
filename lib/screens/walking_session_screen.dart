import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/app_colors.dart';

class WalkingSession extends StatefulWidget {
  final String sessionId;
  final String userId;

  const WalkingSession({super.key, required this.sessionId, required this.userId});

  @override
  State<WalkingSession> createState() => _WalkingSessionState();
}

class _WalkingSessionState extends State<WalkingSession> {
  int _steps = 0;
  int? _lastStepCount;
  String _status = 'Sessie nog niet gestart';
  int stepGoal = 5000;
  final TextEditingController goalController = TextEditingController();

  bool _audioOn = false;
  bool _sessionStarted = false;
  bool _sessionPaused = false;

  late Stream<StepCount> _stepCountStream;
  late StreamSubscription<StepCount> _stepSubscription;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _audioTimer;
  int _audioStep = 0;

  final List<String> _audioFiles = [
    'assets/audio/comeon.mp3',
    'assets/audio/halfway.mp3',
    'assets/audio/takeiteasy.mp3',
  ];

  @override
  void initState() {
    super.initState();
    requestPermission();
    fetchSessionData();
  }

  void requestPermission() async {
    await Permission.activityRecognition.request();
  }

  void initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepSubscription = _stepCountStream.listen((StepCount event) {
      if (mounted && !_sessionPaused) {
        setState(() {
          if (_lastStepCount == null) {
            _lastStepCount = event.steps;
          }
          if (event.steps > _lastStepCount!) {
            _steps += event.steps - _lastStepCount!;
          }
          _lastStepCount = event.steps;
          _status = 'Teller actief';
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
    await FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).get();
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
          backgroundColor: const Color(0xFF141421),
          title: Text("Stapdoel Instellen", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Bijv. 8000",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accentGreen),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setStepGoal();
                Navigator.pop(context);
              },
              child: Text("Opslaan", style: TextStyle(color: AppColors.accentGreen)),
            ),
          ],
        );
      },
    );
  }

  void startSession() {
    if (!_sessionStarted) {
      initPedometer();
      startAudioLoop();
      setState(() {
        _sessionStarted = true;
        _sessionPaused = false;
        _status = 'Buddy Run gestart!';
      });
    }
  }

  void pauseSession() {
    setState(() {
      _sessionPaused = true;
      _status = 'Gepauzeerd';
    });
  }

  void resumeSession() {
    setState(() {
      _sessionPaused = false;
      _status = 'Hervat!';
    });
  }

  void startAudioLoop() {
    _audioTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      if (_audioOn && !_sessionPaused) {
        final file = _audioFiles[_audioStep % _audioFiles.length];
        await _audioPlayer.play(AssetSource(file.replaceFirst('assets/', '')));
        _audioStep++;
      }
    });
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _audioPlayer.dispose();
    _stepSubscription.cancel();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF141421),
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
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF141421),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!_sessionStarted) ...[
                    Text(
                      "Buddy Run Sessie",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // AUDIO SWITCH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Audiobegeleiding", style: TextStyle(color: Colors.white, fontSize: 16)),
                        Switch(
                          activeColor: AppColors.accentGreen,
                          value: _audioOn,
                          onChanged: (val) {
                            setState(() {
                              _audioOn = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // STEP GOAL
                    Text("Stapdoel: $stepGoal stappen",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: openGoalSettings,
                      child: Text("Wijzig doel", style: TextStyle(color: AppColors.accentGreen)),
                    ),
                    const SizedBox(height: 20),
                    // START KNOP
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.play_arrow),
                        label: Text("Start Buddy Run"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: startSession,
                      ),
                    ),
                  ],

                  if (_sessionStarted) ...[
                    const SizedBox(height: 10),
                    // STEP DATA
                    stepsDisplay(),
                    const SizedBox(height: 16),
                    _statusWidget(),
                    const SizedBox(height: 20),
                    // CONTROLS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _circleButton(Icons.pause, AppColors.accentGreen, pauseSession),
                        _circleButton(Icons.play_arrow, Colors.white24, resumeSession),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



  Widget stepsDisplay() => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('walking_sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          var data = snapshot.data!.data() as Map<String, dynamic>;
          int hostSteps = data['hostSteps'] ?? 0;
          int buddySteps = data['buddySteps'] ?? 0;
          int totalSteps = hostSteps + buddySteps;
          double progress = (totalSteps / stepGoal).clamp(0.0, 1.0);

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
                backgroundColor: Colors.white24,
                color: AppColors.accentGreen,
              ),
              const SizedBox(height: 8),
              Text(
                '$totalSteps / $stepGoal stappen gezet',
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
        Text('$count',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statusWidget() => Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accentGreen, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'STATUS: $_status',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      );

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
