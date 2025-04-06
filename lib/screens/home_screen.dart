import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'walking_session_screen.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String weatherInfo = 'Weer laden...';
  final TextEditingController sessionController = TextEditingController();
  int _selectedIndex = 0;

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
        final temp = data['main']['temp'].round();
        final weatherMain = data['weather'][0]['main'];
        weatherInfo = "$temp°C | $weatherMain";
      });
    } else {
      setState(() {
        weatherInfo = 'Weer niet beschikbaar';
      });
    }
  }

  Future<String> createSession(String hostId) async {
    String sessionId = (100000 + Random().nextInt(900000)).toString();
    final sessionRef =
        FirebaseFirestore.instance.collection('walking_sessions').doc(sessionId);

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
    await FirebaseFirestore.instance
        .collection('walking_sessions')
        .doc(sessionId)
        .update({'buddyId': buddyId});
  }

  void showSessionPopup(String sessionId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Sessie succesvol aangemaakt!",
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Geef deze code door aan je buddy om samen te starten:",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          sessionId,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.white70),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: sessionId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sessie-ID gekopieerd!")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: sessionId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sessie-ID gekopieerd!")),
                          );
                        },
                        child: Text("Kopieer", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WalkingSession(sessionId: sessionId, userId: "host"),
                            ),
                          );
                        },
                        child: Text("Start als Host"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141421),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF141421),
        centerTitle: true,
        title: Image.asset('assets/images/fitquest_logo.png', height: 40),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welkom bij FitQuest!', style: _sectionTitleStyle()),
          const SizedBox(height: 6),
          Text(
            'FitQuest helpt je om samen met een buddy te wandelen of rennen. Vergelijk stappen, motiveer elkaar en maak samen progressie!',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardBox(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📍 Weer in Tilburg", style: _subTitleStyle()),
                const SizedBox(height: 5),
                Text(weatherInfo, style: _infoTextStyle()),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('Samen Rennen', style: _sectionTitleStyle()),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: Icon(Icons.directions_run),
            label: Text("Samen Rennen"),
            style: _mainButtonStyle(),
            onPressed: () async {
              String newSessionId = await createSession("host");
              showSessionPopup(newSessionId);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: sessionController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Voer sessie-ID in',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            child: Text("Sessie joinen"),
            style: _mainButtonStyle(),
            onPressed: () async {
              final enteredId = sessionController.text.trim();
              if (enteredId.isNotEmpty) {
                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('walking_sessions')
                      .doc(enteredId)
                      .get();
                  if (!doc.exists) throw 'Sessie niet gevonden.';
                  await joinSession(enteredId, "buddy");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WalkingSession(sessionId: enteredId, userId: "buddy"),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 30),
          Text('Jouw All-Time Statistieken', style: _sectionTitleStyle()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardBox(),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _alignedStat("12", "Runs"),
                    _alignedStat("38.4 km", "Afstand"),
                    _alignedStat("5:10", "Gem. tempo"),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _alignedStat("9.2 km", "Langste run"),
                    _alignedStat("1.540", "Calorieën"),
                    _alignedStat("6", "Buddies"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text("Recente Buddy Runs", style: _sectionTitleStyle()),
          const SizedBox(height: 16),
          _buddyRunCard("Joost Verhoeven", "Gisteren", "5.2 km", "28:36", "5:30/km", "5:25/km", "342 kcal", "JV"),
          const SizedBox(height: 12),
          _buddyRunCard("Lisa Bakker", "3 dagen geleden", "3.5 km", "19:25", "5:40/km", "5:45/km", "215 kcal", "LB"),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0D0D14),
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Buddies'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Instellingen'),
        ],
      ),
    );
  }

  // -------------------- STYLES --------------------

  BoxDecoration _cardBox() => BoxDecoration(
        color: const Color(0xFF1F1F2E),
        borderRadius: BorderRadius.circular(12),
      );

  TextStyle _sectionTitleStyle() => TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  TextStyle _subTitleStyle() => TextStyle(
        color: Colors.white70,
        fontSize: 16,
      );

  TextStyle _infoTextStyle() => TextStyle(
        color: Colors.white,
        fontSize: 18,
      );

  ButtonStyle _mainButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGreen,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _alignedStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buddyRunCard(
    String name,
    String date,
    String distance,
    String duration,
    String myPace,
    String buddyPace,
    String calories,
    String initials,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(initials, style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Met $name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(color: Colors.white60, fontSize: 13)),
                    Text("$distance – $duration", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("Voltooid", style: TextStyle(color: const Color(0xFF141421), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn("Jouw tempo", myPace),
              _infoColumn("Buddy tempo", buddyPace),
              _infoColumn("Calorieën", calories),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
