import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FC2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// SCREEN 1: HOME (TODAY'S FIXTURES & BUTTONS)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String todayMatchesText = "Loading today's matches...";
  final String apiToken = 'efd75b6e430f4c81a3472169e3418eb1'; // Your Token

  @override
  void initState() {
    super.initState();
    fetchTodayMatches();
  }

  Future<void> fetchTodayMatches() async {
    final String todayDate = DateTime.now().toIso8601String().substring(0, 10);
    const String url = 'https://api.football-data.org/v4/competitions/WC/matches';

    try {
      final response = await http.get(Uri.parse(url), headers: {'X-Auth-Token': apiToken});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List matches = data['matches'];
        String currentFixtures = "";

        for (var match in matches) {
          if (match['utcDate'].toString().contains(todayDate)) {
            String home = match['homeTeam']['name'] ?? 'TBD';
            String away = match['awayTeam']['name'] ?? 'TBD';
            String status = match['status'] == 'TIMED' ? 'Upcoming' : 'Live';
            currentFixtures += "⚽ $home vs $away ($status)\n\n";
          }
        }

        setState(() {
          todayMatchesText = currentFixtures.isEmpty 
              ? "No World Cup matches scheduled for today!" 
              : currentFixtures.trim();
        });
      } else {
        setState(() => todayMatchesText = "Failed to synchronize with server.");
      }
    } catch (e) {
      setState(() => todayMatchesText = "Connection error. Please verify network access.");
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open external app for: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FC2026', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.green[800],
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Clickable Results Tab/Card Selector
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResultsScreen(apiToken: apiToken)),
                );
              },
              child: Card(
                color: Colors.amber[800],
                elevation: 4,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white),
                      SizedBox(width: 10),
                      Text("👉 VIEW PREVIOUS MATCH RESULTS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // Main Today's Fixture Showcase Window
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Today's Match Schedules", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      const Divider(height: 20, thickness: 1.5),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(todayMatchesText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Deep Integration Application Platform Routing Buttons
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], minimumSize: const Size.fromHeight(50)),
              onPressed: () => _launchExternalUrl('https://www.youtube.com/watch?v=ITx_k7uNFP4'),
              icon: const Icon(Icons.live_tv, color: Colors.white),
              label: const Text('Watch Somoy TV Live', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], minimumSize: const Size.fromHeight(50)),
              onPressed: () => _launchExternalUrl('https://www.btvlive.gov.bd/channel/BTV'),
              icon: const Icon(Icons.language, color: Colors.white),
              label: const Text('Watch BTV Live (Browser)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], minimumSize: const Size.fromHeight(50)),
              onPressed: () => _launchExternalUrl('https://www.youtube.com/@TSportsLiveBangladesh'),
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: const Text('Watch T Sports Live', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 2: RESULTS VIEW (HISTORICAL SCORES)
// ==========================================
class ResultsScreen extends StatefulWidget {
  final String apiToken;
  const ResultsScreen({Key? key, required this.apiToken}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List completedMatches = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchPreviousResults();
  }

  Future<void> fetchPreviousResults() async {
    const String url = 'https://api.football-data.org/v4/competitions/WC/matches?status=FINISHED';
    try {
      final response = await http.get(Uri.parse(url), headers: {'X-Auth-Token': widget.apiToken});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          completedMatches = data['matches'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Unable to fetch completed results matrix.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Network tracking failure.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(fontSize: 16, color: Colors.red)))
              : completedMatches.isEmpty
                  ? const Center(child: Text("No completed matches recorded yet.", style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: completedMatches.length,
                      itemBuilder: (context, index) {
                        final match = completedMatches[index];
                        final homeTeam = match['homeTeam']['name'] ?? 'Unknown';
                        final awayTeam = match['awayTeam']['name'] ?? 'Unknown';
                        final homeScore = match['score']['fullTime']['home'] ?? 0;
                        final awayScore = match['score']['fullTime']['away'] ?? 0;
                        final matchDate = match['utcDate'].toString().substring(0, 10);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            leading: Text(matchDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(homeTeam, style: const TextStyle(fontWeight: FontWeight.bold))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, py: 4),
                                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                  child: Text("$homeScore - $awayScore", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                ),
                                Expanded(child: Text(awayTeam, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}