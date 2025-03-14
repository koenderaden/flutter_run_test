import 'package:flutter/material.dart';
import 'walking_session_screen.dart';
import '../utils/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String weatherInfo = 'Weer laden...';

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
        weatherInfo =
            "${data['main']['temp'].round()}°C ${data['weather'][0]['main']}";
      });
    } else {
      setState(() {
        weatherInfo = 'Weer niet beschikbaar';
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalkingSession()),
              ),
            ),
            const SizedBox(height: 30),
            _sectionTitle('Snelle Navigatie'),
            const SizedBox(height: 15),
            _quickNavGrid(),
            const SizedBox(height: 30),
            _sectionTitle('Jouw Statistieken'),
            const SizedBox(height: 15),
            _statisticsCard(),
            const SizedBox(height: 30),
            _sectionTitle('Recente Buddy Runs'),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Je hebt nog geen runs gedaan.',
                style: TextStyle(color: AppColors.textWhite, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeWidget() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    'Vandaag is het een geweldige dag om te trainen!',
                    style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: AppColors.accentGreen, size: 20),
                      const SizedBox(width: 5),
                      Text(weatherInfo,
                          style: TextStyle(color: AppColors.textWhite, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.directions_run, color: AppColors.accentGreen, size: 40),
          ],
        ),
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

  Widget _navCard(IconData icon, String title, String subtitle) => InkWell(
        onTap: () {},
        child: Container(
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
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textWhite.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _statisticsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.2),
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
}
