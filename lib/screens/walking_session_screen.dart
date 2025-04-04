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

  Timer? _timer;
  String _elapsedTime = "00:00";
  DateTime? _sessionStartTime;

  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    requestPermission();
    listenToSessionChanges();
  }

  void requestPermission() async {
    await Permission.activityRecognition.request();
  }

  void listenToSessionChanges() {
    FirebaseFirestore.instance
        .collection('walking_sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;

      if (data['stepGoal'] != null && data['stepGoal'] != stepGoal) {
        setState(() {
          stepGoal = data['stepGoal'];
        });
      }

      if (data['sessionStarted'] == true && !_sessionStarted) {
        final Timestamp ts = data['startTimestamp'];
        startSessionFromTimestamp(ts);
      }
    });
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
        _status = 'Fout met stappenteller: $error';
      });
    });
  }

  void updateStepsInFirestore() {
    FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).update({
      widget.userId == 'host' ? 'hostSteps' : 'buddySteps': _steps,
    });
  }

  void setStepGoal() {
    int? newGoal = int.tryParse(goalController.text);
    if (newGoal != null && newGoal > 0) {
      FirebaseFirestore.instance
          .collection('walking_sessions')
          .doc(widget.sessionId)
          .update({'stepGoal': newGoal});
      goalController.clear();
    }
  }

  void openGoalSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141421),
          title: Text("Stapdoel instellen", style: TextStyle(color: Colors.white)),
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

  void startSession() async {
    await FirebaseFirestore.instance.collection('walking_sessions').doc(widget.sessionId).update({
      'sessionStarted': true,
      'startTimestamp': FieldValue.serverTimestamp(),
    });
  }

  void startSessionFromTimestamp(Timestamp timestamp) {
    _sessionStartTime = timestamp.toDate();

    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_sessionStartTime != null) {
        final now = DateTime.now();
        final elapsed = now.difference(_sessionStartTime!);
        final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
        final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() {
          _elapsedTime = "$minutes:$seconds";
        });
      }
    });

    setState(() {
      _sessionStarted = true;
      _sessionPaused = false;
      _status = 'Sessie gestart!';
    });

    initPedometer();
    startAudioLoop();
  }

  void pauseSession() {
    setState(() {
      _sessionPaused = true;
      _status = 'Sessie gepauzeerd';
    });
  }

  void resumeSession() {
    setState(() {
      _sessionPaused = false;
      _status = 'Sessie hervat';
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

  void _toggleCallingAudio() async {
    if (!_isCalling) {
      await _audioPlayer.play(AssetSource('audio/calling.mp3'));
      setState(() {
        _isCalling = true;
      });
    } else {
      await _audioPlayer.stop();
      setState(() {
        _isCalling = false;
      });
    }
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _audioPlayer.dispose();
    _stepSubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141421),
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF141421),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_sessionStarted) ...[
                      Text("Buddy Run Sessie", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
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
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Stapdoel: $stepGoal stappen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            if (widget.userId == 'host')
                              TextButton(
                                onPressed: openGoalSettings,
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: Text("Wijzig doel", style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w500)),
                              )
                            else
                              Text("Alleen de host kan het doel wijzigen.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.userId == 'host')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.play_arrow),
                            label: Text("Start Buddy Run"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: startSession,
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            "Wacht tot de host de sessie start...",
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ),
                    ],
                    if (_sessionStarted) ...[
                      const SizedBox(height: 10),
                      Text("Duur: $_elapsedTime", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      stepsDisplay(),
                      const SizedBox(height: 16),
                      _statusWidget(),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _circleButton(Icons.pause, AppColors.accentGreen, pauseSession),
                          _circleButton(Icons.play_arrow, Colors.white24, resumeSession),
                          _circleButton(_isCalling ? Icons.stop : Icons.phone, _isCalling ? Colors.orangeAccent : Colors.greenAccent.shade400, _toggleCallingAudio),
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
                  _stepCount(widget.userId == 'host' ? "Jij" : "Buddy", hostSteps, Icons.person),
                  _stepCount(widget.userId == 'buddy' ? "Jij" : "Buddy", buddySteps, Icons.person_outline),
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
              Text('$totalSteps / $stepGoal stappen gezet', style: TextStyle(color: Colors.white70, fontSize: 14)),
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

  Widget _statusWidget() => Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accentGreen, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text('STATUS: $_status', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
