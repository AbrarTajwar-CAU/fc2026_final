import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Handles clean localized hour formatting templates

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FC2026 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// SCREEN 1: HOME (WORLD CUP FOCUS & TV BUTTONS)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String todayFixturesSummary = "Loading World Cup data...";
  String fixtureDisplayDate = "";
  final String apiToken = 'efd75b6e430f4c81a3472169e3418eb1';

  @override
  void initState() {
    super.initState();
    fetchWorldCupFixtures();
  }

  Future<void> fetchWorldCupFixtures() async {
    const String url = 'https://api.football-data.org/v4/competitions/WC/matches';
    try {
      final response = await http.get(Uri.parse(url), headers: {'X-Auth-Token': apiToken});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List matches = data['matches'] ?? [];
        
        final String todayStr = DateTime.now().toIso8601String().substring(0, 10);
        String runningText = "";
        String foundDate = todayStr;

        // 1. Scan for games scheduled on the user's current calendar day
        for (var match in matches) {
          DateTime localTime = DateTime.parse(match['utcDate']).toLocal();
          String localMatchDay = localTime.toIso8601String().substring(0, 10);

          if (localMatchDay == todayStr) {
            String home = match['homeTeam']['name'] ?? 'TBD';
            String away = match['awayTeam']['name'] ?? 'TBD';
            String formattedTime = DateFormat('hh:mm a').format(localTime);
            runningText += "⚽ $home vs $away\n⏰ $formattedTime (Your Time)\n\n";
          }
        }

        // 2. Fallback: Search ahead chronologically for the next upcoming round date
        if (runningText.isEmpty) {
          for (var match in matches) {
            DateTime localTime = DateTime.parse(match['utcDate']).toLocal();
            String localMatchDay = localTime.toIso8601String().substring(0, 10);
            if (localMatchDay.compareTo(todayStr) > 0) {
              foundDate = localMatchDay;
              break;
            }
          }
          
          for (var match in matches) {
            DateTime localTime = DateTime.parse(match['utcDate']).toLocal();
            String localMatchDay = localTime.toIso8601String().substring(0, 10);

            if (localMatchDay == foundDate) {
              String home = match['homeTeam']['name'] ?? 'TBD';
              String away = match['awayTeam']['name'] ?? 'TBD';
              String formattedTime = DateFormat('hh:mm a').format(localTime);
              runningText += "⚽ $home vs $away\n⏰ $formattedTime (Your Time)\n\n";
            }
          }
        }

        setState(() {
          fixtureDisplayDate = foundDate;
          todayFixturesSummary = runningText.isEmpty 
              ? "No upcoming World Cup fixtures found." 
              : runningText.trim();
        });
      } else {
        setState(() => todayFixturesSummary = "Error syncing with server.");
      }
    } catch (e) {
      setState(() => todayFixturesSummary = "Network connection failed.");
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FC2026 Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CompetitionSelectorScreen(apiToken: apiToken)),
                );
              },
              child: Card(
                color: Colors.amber[800],
                elevation: 4,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, color: Colors.white),
                      SizedBox(width: 10),
                      Text("📊 BROWSE ALL COMPETITION RESULTS", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllFixturesScreen(apiToken: apiToken)),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text("World Cup Schedules ($fixtureDisplayDate)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1.2),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Text(todayFixturesSummary, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w600, color: Colors.black87)),
                            ),
                          ),
                        ),
                        const Text("👉 Tap card to view all upcoming schedules", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], minimumSize: const Size.fromHeight(48)),
              onPressed: () => _launchExternalUrl('https://www.youtube.com/watch?v=ITx_k7uNFP4'),
              icon: const Icon(Icons.live_tv, color: Colors.white),
              label: const Text('Watch Somoy TV Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], minimumSize: const Size.fromHeight(48)),
              onPressed: () => _launchExternalUrl('https://www.btvlive.gov.bd/channel/BTV'),
              icon: const Icon(Icons.language, color: Colors.white),
              label: const Text('Watch BTV Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], minimumSize: const Size.fromHeight(48)),
              onPressed: () => _launchExternalUrl('https://www.youtube.com/@TSportsLiveBangladesh'),
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: const Text('Watch T Sports Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN 2: ALL UPCOMING WC FIXTURES LIST
// ==========================================
class AllFixturesScreen extends StatefulWidget {
  final String apiToken;
  const AllFixturesScreen({Key? key, required this.apiToken}) : super(key: key);

  @override
  State<AllFixturesScreen> createState() => _AllFixturesScreenState();
}

class _AllFixturesScreenState extends State<AllFixturesScreen> {
  List totalSchedules = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    const String url = 'https://api.football-data.org/v4/competitions/WC/matches';
    try {
      final response = await http.get(Uri.parse(url), headers: {'X-Auth-Token': widget.apiToken});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawMatches = data['matches'] ?? [];
        final DateTime now = DateTime.now();
        
        setState(() {
          totalSchedules = rawMatches.where((m) {
            DateTime localTime = DateTime.parse(m['utcDate']).toLocal();
            return m['status'] == 'TIMED' || localTime.isAfter(now);
          }).toList();
          loading = false;
        });
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full World Cup Schedules', style: TextStyle(color: Colors.white)), backgroundColor: Colors.indigo[900], iconTheme: const IconThemeData(color: Colors.white)),
      body: loading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: totalSchedules.length,
              itemBuilder: (context, index) {
                final item = totalSchedules[index];
                DateTime localTime = DateTime.parse(item['utcDate']).toLocal();
                String displayDay = localTime.toIso8601String().substring(0, 10);
                String displayTime = DateFormat('hh:mm a').format(localTime);

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time_filled, color: Colors.indigo),
                    title: Text("${item['homeTeam']['name'] ?? 'TBD'} vs ${item['awayTeam']['name'] ?? 'TBD'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Date: $displayDay | Kickoff: $displayTime"),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// SCREEN 3: RESULTS ENGINE WITH LEAGUE PICKER
// ==========================================
class CompetitionSelectorScreen extends StatefulWidget {
  final String apiToken;
  const CompetitionSelectorScreen({Key? key, required this.apiToken}) : super(key: key);

  @override
  State<CompetitionSelectorScreen> createState() => _CompetitionSelectorScreenState();
}

class _CompetitionSelectorScreenState extends State<CompetitionSelectorScreen> {
  final Map<String, String> leagueDictionary = {
    'WC': 'FIFA World Cup',
    'CL': 'UEFA Champions League',
    'BL1': 'Bundesliga',
    'DED': 'Eredivisie',
    'BSA': 'Campeonato Brasileiro Série A',
    'PD': 'Primera Division',
    'FL1': 'Ligue 1',
    'ELC': 'Championship',
    'PPL': 'Primeira Liga',
    'EC': 'European Championship',
    'SA': 'Serie A',
    'PL': 'Premier League'
  };

  String activeCode = 'PL';
  List historicalResults = [];
  bool dataLoading = false;

  @override
  void initState() {
    super.initState();
    refreshLeagueData(activeCode);
  }

  Future<void> refreshLeagueData(String code) async {
    setState(() {
      dataLoading = true;
      activeCode = code;
    });

    final String url = 'https://api.football-data.org/v4/competitions/$code/matches?status=FINISHED';
    try {
      final response = await http.get(Uri.parse(url), headers: {'X-Auth-Token': widget.apiToken});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          List parsed = data['matches'] ?? [];
          historicalResults = parsed.reversed.toList();
          dataLoading = false;
        });
      } else {
        setState(() {
          historicalResults = [];
          dataLoading = false;
        });
      }
    } catch (_) {
      setState(() => dataLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results Explorer', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.amber[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Text("Select League: ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: activeCode,
                    isExpanded: true,
                    items: leagueDictionary.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) refreshLeagueData(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dataLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : historicalResults.isEmpty
                    ? const Center(child: Text("No finished matches found for this competition cycle."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: historicalResults.length,
                        itemBuilder: (context, index) {
                          final match = historicalResults[index];
                          final hTeam = match['homeTeam']['name'] ?? 'Unknown';
                          final aTeam = match['awayTeam']['name'] ?? 'Unknown';
                          final hScore = match['score']['fullTime']['home'] ?? 0;
                          final aScore = match['score']['fullTime']['away'] ?? 0;
                          
                          DateTime localTime = DateTime.parse(match['utcDate']).toLocal();
                          String localDateStr = localTime.toIso8601String().substring(0, 10);
                          final matchday = match['matchday'] ?? '?';

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Text("Matchday $matchday — $localDateStr", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(hTeam, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(5)),
                                        child: Text("$hScore - $aScore", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                                      ),
                                      Expanded(child: Text(aTeam, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}