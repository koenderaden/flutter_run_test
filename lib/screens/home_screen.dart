import 'package:flutter/material.dart';
import 'walking_session_screen.dart';
import '../utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String weatherInfo = 'Weer laden...';
  final TextEditingController sessionController = TextEditingController();
  String sessionId = '';

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    const apiKey = 'd2f8ad0b8e9d7d2177d5f28e686ddbb4';
    const city = 'Tilburg,nl';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        weatherInfo = "${data['main']['temp'].round()}°C ${data['weather'][0]['main']}";
      });
    } else {
      setState(() {
        weatherInfo = 'Weer niet beschikbaar';
      });
    }
  }

  void showSessionPopup(String sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Sessie Aangemaakt",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Jouw sessie-ID:",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SelectableText(
                sessionId,
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "⚠️ Deel deze code met je buddy. Alleen je buddy moet deze code invoeren om te joinen.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: sessionId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Sessie-ID gekopieerd! Deel dit met je buddy.")),
                );
              },
              child: Text("Kopiëren"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalkingSession(sessionId: sessionId, userId: "host"),
                  ),
                );
              },
              child: Text("Ga verder als Host"),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welkom bij FitQuest, dé app om samen hard te lopen!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textWhite, fontSize: 16),
            ),
            const SizedBox(height: 20),
            _welcomeWidget(),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.directions_run),
              label: const Text('Run Together', style: TextStyle(fontSize: 18)),
              onPressed: () async {
                String newSessionId = await createSession("host");
                showSessionPopup(newSessionId);
              },
            ),
            const SizedBox(height: 10),

            if (sessionId.isNotEmpty)
              Column(
                children: [
                  Text(
                    "Jouw Sessie-ID: $sessionId",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: sessionId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Sessie-ID gekopieerd!")),
                      );
                    },
                    child: Text("Kopieer Sessie-ID"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WalkingSession(sessionId: sessionId, userId: "host"),
                        ),
                      );
                    },
                    child: Text("Start Sessie"),
                  ),
                ],
              ),

            const SizedBox(height: 30),
            _sectionTitle('Sessie Joinen'),

            TextField(
              controller: sessionController,
              decoration: InputDecoration(
                labelText: 'Voer Sessie-ID in',
                labelStyle: TextStyle(color: AppColors.textWhite),
                filled: true,
                fillColor: AppColors.accentBlue, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accentGreen, width: 2),
                ),
              ),
              style: TextStyle(color: AppColors.textWhite),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.background,
              ),
              onPressed: () {
                String enteredSessionId = sessionController.text;
                if (enteredSessionId.isNotEmpty) {
                  joinSession(enteredSessionId, "buddy");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalkingSession(sessionId: enteredSessionId, userId: "buddy"),
                    ),
                  );
                }
              },
              child: const Text('Join Sessie'),
            ),

            const SizedBox(height: 30),
            _sectionTitle('Snelle Navigatie'),
            _quickNavGrid(),
            const SizedBox(height: 30),

            _sectionTitle('Jouw Statistieken'),
            _statisticsCard(),
          ],
        ),
      ),
    );
  }

  Widget _welcomeWidget() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue, 
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Goedemorgen sporter!',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(weatherInfo, style: TextStyle(color: AppColors.textWhite, fontSize: 18)),
          ],
        ),
      );

  Widget _quickNavGrid() => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _navCard(Icons.people, 'Mijn Buddies', 'Beheer je hardloopmaatjes'),
          _navCard(Icons.history, 'Geschiedenis', 'Bekijk je eerdere runs'),
          _navCard(Icons.settings, 'Instellingen', 'Pas je voorkeuren aan'),
          _navCard(Icons.map, 'Locaties', 'Ontdek hardlooproutes'),
        ],
      );

  Widget _navCard(IconData icon, String title, String subtitle) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accentGreen),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accentGreen, size: 30),
            Text(title, style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _statisticsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statisticColumn('0', 'Runs'),
                _statisticColumn('0 km', 'Totaal'),
                _statisticColumn('0:00', 'Gem. Tempo'),
              ],
            ),
          ],
        ),
      );

  Widget _statisticColumn(String value, String label) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textWhite.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Future<String> createSession(String hostId) async {
    String sessionId = (100000 + Random().nextInt(900000)).toString();
    final sessionRef = FirebaseFirestore.instance.collection('walking_sessions').doc(sessionId);

    await sessionRef.set({
      'sessionId': sessionId,
      'hostId': hostId,
      'buddyId': "",
      'hostSteps': 0,
      'buddySteps': 0,
    });

    return sessionId;
  }

  Future<void> joinSession(String sessionId, String buddyId) async {
    await FirebaseFirestore.instance.collection('walking_sessions').doc(sessionId).update({
      'buddyId': buddyId,
    });
  }
}
