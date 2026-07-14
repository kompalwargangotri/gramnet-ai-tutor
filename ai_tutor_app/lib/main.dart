import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

String globalServerUrl = "http://10.0.2.2:8000";
bool globalIsOffline = true;
bool globalIsManualOffline = false; // NEW: Manual offline override
bool globalHasInternet = false;
bool globalHasServer = false;
// Global stream to notify all screens to refresh their data (XP, Streak, etc.)
final StreamController<void> globalUpdateTrigger = StreamController.broadcast();

// Debug variables for UI debug panel
String debugGlobalServerUrl = "None";
bool debugGlobalIsOffline = true;
bool debugGlobalHasServer = false;
String debugLastHealthStatusCode = "None";
String debugLastHealthResponseBody = "None";
String debugLastExceptionMessage = "None";
String debugLastActionStatus = "Idle";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GramNet AI Tutor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFFFC107),
          surface: Colors.white,
        ),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthCheck()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Subtle particle/dot background could go here
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset('assets/logo.png', height: 140),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "GRAMNET AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "SMART VILLAGE TUTOR",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('user_name');
    setState(() {
      _isLoggedIn = name != null && name.isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _login() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your name!")));
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF303F9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(40),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'logo',
                      child: Image.asset('assets/logo.png', height: 100),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Student Login",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Enter your name to start your mission",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        labelStyle: const TextStyle(color: Colors.indigo),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Colors.indigo,
                        ),
                        filled: true,
                        fillColor: Colors.indigo.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.indigo,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: Colors.indigo.withOpacity(0.5),
                      ),
                      onPressed: _login,
                      child: const Text(
                        "ACCESS DASHBOARD",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatScreen(),
    const QuizScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _syncPendingScores();
  }

  Future<void> _syncPendingScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList('pending_sync_scores') ?? [];
    if (pending.isEmpty) return;

    print("Checking internet for sync...");
    try {
      final check = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      if (check.statusCode == 204) {
        List<String> remaining = [];
        for (var item in pending) {
          final data = jsonDecode(item);
          try {
            // Need a way to access globalServerUrl, which is defined in lib/main.dart globally
            final response = await http
                .post(
                  Uri.parse("$globalServerUrl/submit_score"),
                  headers: {"Content-Type": "application/json"},
                  body: item,
                )
                .timeout(const Duration(seconds: 5));

            if (response.statusCode != 200) remaining.add(item);
          } catch (e) {
            remaining.add(item);
          }
        }
        await prefs.setStringList('pending_sync_scores', remaining);
        if (remaining.length < pending.length) {
          print("Synced ${pending.length - remaining.length} scores!");
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: "Tutor",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: "Quiz",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CHAT SCREEN (WITH SIDEBAR)
// ==========================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  late FlutterTts _flutterTts;

  // Chat History Management
  List<String> _chatSessionIds = [];
  String? _currentSessionId;

  bool _isPlayingText = false;
  String _currentlyPlayingText = "";
  String _language = "en"; // Default for chat
  Timer? _networkTimer;
  String _userName = "Student";
  int _streakCount = 0;
  String _championName = "Loading...";
  String _championXP = "0 XP";
  String _championClass = "10";
  StreamSubscription? _updateSub;
  int _userLevel = 1;
  int _totalXP = 0;

  // NEW: UI Translations
  final Map<String, Map<String, String>> _uiTranslations = {
    "en": {
      "tutor_ready": "Ready to Learn, {name}!",
      "tap_mic": "Tap the Microphone to speak or type a question.",
      "new_chat": "New Chat",
      "daily_revision": "Daily Revision",
      "village_champion": "VILLAGE CHAMPION",
      "notice_board": "VILLAGE NOTICE BOARD",
    },
    "hi": {
      "tutor_ready": "सीखने के लिए तैयार, {name}!",
      "tap_mic": "बोलने के लिए माइक्रोफ़ोन दबाएं या प्रश्न टाइप करें।",
      "new_chat": "नया चैट",
      "daily_revision": "दैनिक संशोधन",
      "village_champion": "गाँव का चैंपियन",
      "notice_board": "गाँव का सूचना बोर्ड",
    },
    "mr": {
      "tutor_ready": "शिकण्यासाठी तयार, {name}!",
      "tap_mic": "बोलण्यासाठी मायक्रोफोन दाबा किंवा प्रश्न टाइप करा.",
      "new_chat": "नवीन चॅट",
      "daily_revision": "दैनिक उजळणी",
      "village_champion": "गावचा चॅम्पियन",
      "notice_board": "गावचा सूचना फलक",
    },
  };

  String t(String key) {
    String text = _uiTranslations[_language]?[key] ?? key;
    return text.replaceAll("{name}", _userName);
  }

  final List<String> _villageNotices = [
    "📢 Tomorrow is a Science Fair in the Village Square!",
    "📖 Library has new NCERT books for Class 10.",
    "🏆 Top 3 students will get a special prize this Sunday.",
    "💧 Reminder: Keep the village school clean and green!",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
    _seedLibrary();
    _initializeGlossaryAndSynonyms();
    _loadAllSessions();
    _loadUserName();
    _loadStreak();
    _loadXP(); // NEW
    _fetchDynamicChampion();
    _loadSettings();
    _villageNotices.shuffle(); // Shuffle notices on every start
    _networkTimer = Timer.periodic(const Duration(seconds: 15), _checkNetwork);
    _checkNetwork(null);
    _updateSub = globalUpdateTrigger.stream.listen((_) {
      _loadStreak();
      _loadXP(); // NEW
      _fetchDynamicChampion();
    });
  }

  @override
  void dispose() {
    _networkTimer?.cancel();
    _updateSub?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _fetchDynamicChampion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Show Offline Fallback IMMEDIATELY (No Delay)
    List<String> scores = prefs.getStringList('quiz_scores') ?? [];
    if (scores.isNotEmpty) {
      if (mounted) {
        setState(() {
          _championName = _userName;
          _championXP = "Last: ${scores.first.split(' ')[0]}";
          _championClass = "10";
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _championName = "No Champion Yet";
          _championXP = "Be the first!";
        });
      }
    }

    // 2. Try fetching from server in background
    try {
      final response = await http
          .get(Uri.parse("$globalServerUrl/leaderboard"))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> lb = data["leaderboard"] ?? [];
        if (lb.isNotEmpty && mounted) {
          setState(() {
            _championName = lb[0]["name"];
            _championXP = "${lb[0]["score"]}/15";
            _championClass = lb[0]["class_level"] ?? "10";
          });
        }
      }
    } catch (e) {
      print("Dynamic champion sync skipped: $e");
    }
  }

  Future<void> _loadXP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> scores = prefs.getStringList('quiz_scores') ?? [];
    int totalEarned = 0;
    for (var s in scores) {
      try {
        totalEarned += int.parse(s.split("/")[0]);
      } catch (_) {}
    }
    // Each chat message also counts (simulated by streak * 5 for now, or just total)
    int chatXP = (prefs.getInt('chat_xp_total') ?? 0);

    setState(() {
      _totalXP = (totalEarned * 10) + chatXP; // 10 XP per correct answer
      _userLevel = (_totalXP ~/ 100) + 1;
    });
  }

  Future<void> _loadStreak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _streakCount = prefs.getInt('daily_streak') ?? 0;
    });
  }

  Future<void> _seedLibrary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('library_manifest') == null) {
      Map<String, dynamic> manifest = {
        "Science (English)": [
          "Gravity pulls objects toward each other.",
          "Plants use photosynthesis to make food.",
          "Electric current is the flow of electrons.",
          "Pollen grains are fine powders produced by flowers for reproduction.",
        ],
        "Math (English)": [
          "Area of circle is πr².",
          "Prime numbers have only two factors: 1 and themselves.",
          "A triangle has three sides and angles summing to 180°.",
        ],
        "विज्ञान (Hindi)": [
          "गुरुत्वाकर्षण वस्तुओं को एक-दूसरे की ओर खींचता है।",
          "पौधे भोजन बनाने के लिए प्रकाश संश्लेषण का उपयोग करते हैं।",
          "विद्युत धारा इलेक्ट्रॉनों का प्रवाह है।",
          "पराग कण फूलों द्वारा प्रजनन के लिए उत्पादित महीन पाउडर होते हैं।",
        ],
        "गणित (Hindi)": [
          "वृत्त का क्षेत्रफल πr² है।",
          "अभाज्य संख्याओं के केवल दो गुणनखंड होते हैं: 1 और वे स्वयं।",
          "एक त्रिभुज की तीन भुजाएँ होती हैं और कोणों का योग 180° होता है।",
        ],
      };
      await prefs.setString('library_manifest', jsonEncode(manifest));
    }
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String loadedUrl = prefs.getString('global_server_url') ?? "";
    if (loadedUrl.isNotEmpty) {
      while (loadedUrl.endsWith("/")) {
        loadedUrl = loadedUrl.substring(0, loadedUrl.length - 1);
      }
      setState(() {
        globalServerUrl = loadedUrl;
      });
    } else {
      setState(() {
        globalServerUrl = "http://10.0.2.2:8000";
      });
    }
    _checkNetwork(null);
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Student";
    });
  }

  Future<void> _syncPendingScores() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> pending = prefs.getStringList('pending_sync_scores') ?? [];
      if (pending.isEmpty) return;
      List<String> remaining = [];
      for (var p in pending) {
        try {
          final data = jsonDecode(p);
          final response = await http
              .post(
                Uri.parse("$globalServerUrl/submit_score"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 5));
          if (response.statusCode != 200) remaining.add(p);
        } catch (e) {
          remaining.add(p);
        }
      }
      await prefs.setStringList('pending_sync_scores', remaining);
      if (remaining.isEmpty) _fetchDynamicChampion();
    } catch (e) {
      print("Sync error: $e");
    }
  }

  Future<void> debugRawHttp() async {
    try {
      final response = await http
          .get(
            Uri.parse("$globalServerUrl/health"),
            headers: {"Connection": "close"},
          )
          .timeout(const Duration(seconds: 8));

      print("RAW TEST STATUS = ${response.statusCode}");
      print("RAW TEST BODY = ${response.body}");
      setState(() {
        debugLastHealthStatusCode = "${response.statusCode}";
        debugLastHealthResponseBody = response.body.trim();
        debugLastExceptionMessage = "None";
        debugLastActionStatus = "RAW TEST STATUS = ${response.statusCode}";
      });
    } catch (e) {
      print("RAW TEST EXCEPTION = $e");
      setState(() {
        debugLastHealthStatusCode = "Error";
        debugLastHealthResponseBody = "None";
        debugLastExceptionMessage = "RAW TEST EXCEPTION = $e";
        debugLastActionStatus = "RAW TEST FAILED";
      });
    }
  }

  void _checkNetwork(Timer? timer) async {
    if (globalIsManualOffline) {
      if (mounted && !globalIsOffline) {
        setState(() {
          globalIsOffline = true;
        });
      }
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedUrl = prefs.getString('global_server_url') ?? "";

    setState(() {
      debugGlobalServerUrl = globalServerUrl;
      debugGlobalIsOffline = globalIsOffline;
      debugGlobalHasServer = globalHasServer;
      debugLastActionStatus = "Checking health (timeout 8s)...";
    });

    print("=== CHECK NETWORK ===");
    print("globalServerUrl = $globalServerUrl");

    bool hasServer = false;
    String healthStatusStr = "failed";

    // 1. Check current globalServerUrl health (GET "$globalServerUrl/health" with 8s timeout)
    if (globalServerUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse("$globalServerUrl/health"))
            .timeout(const Duration(seconds: 8));
        print("Health status code = ${response.statusCode}");
        print("Health body = ${response.body}");
        healthStatusStr = "${response.statusCode} (${response.body.trim()})";

        setState(() {
          debugLastHealthStatusCode = "${response.statusCode}";
          debugLastHealthResponseBody = response.body.trim();
          debugLastExceptionMessage = "None";
          debugLastActionStatus = "Health check successful";
        });

        if (response.statusCode == 200 && response.body.contains("ok")) {
          hasServer = true;
        }
      } catch (e) {
        print("Exception = $e");
        healthStatusStr = "error ($e)";
        hasServer = false;

        setState(() {
          debugLastHealthStatusCode = "Error";
          debugLastHealthResponseBody = "None";
          debugLastExceptionMessage = "$e";
          debugLastActionStatus = "Health check failed";
        });
      }
    } else {
      setState(() {
        debugLastActionStatus = "globalServerUrl is empty";
      });
    }

    // 2. Auto-scan ONLY if saved backend URL is empty and server was not found at globalServerUrl
    if (!hasServer && savedUrl.isEmpty && !kIsWeb) {
      print("[CheckNetwork] Saved URL is empty. Running auto-scan...");
      final List<String> probeIPs = [
        "192.168.137.1", // Windows hotspot default
        "192.168.43.1", // Android hotspot default
        "10.0.2.2", // Android Emulator host default
        "192.168.1.1", // Router default
      ];

      // Also dynamically check current subnet segment if possible
      try {
        final List<NetworkInterface> interfaces = await NetworkInterface.list();
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              final ip = addr.address;
              final parts = ip.split('.');
              if (parts.length == 4) {
                // Try gateway .1
                final gatewayIp = "${parts[0]}.${parts[1]}.${parts[2]}.1";
                if (!probeIPs.contains(gatewayIp)) {
                  probeIPs.add(gatewayIp);
                }
                // Try laptop's IP segment probe for first few addresses (e.g. .2 to .15)
                for (int i = 2; i <= 15; i++) {
                  final segmentIp = "${parts[0]}.${parts[1]}.${parts[2]}.$i";
                  if (segmentIp != ip && !probeIPs.contains(segmentIp)) {
                    probeIPs.add(segmentIp);
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      // Probe candidates sequentially with a fast 1-second timeout using /health
      for (var ip in probeIPs) {
        final candidateUrl = "http://$ip:8000";
        if (candidateUrl == globalServerUrl) continue;

        try {
          final probeCheck = await http
              .get(Uri.parse("$candidateUrl/health"))
              .timeout(const Duration(seconds: 1));
          if (probeCheck.statusCode == 200 && probeCheck.body.contains("ok")) {
            hasServer = true;
            globalServerUrl =
                candidateUrl; // Set transiently, do not overwrite savedUrl in prefs since it's empty
            print(
              "[CheckNetwork] Auto-detected local AI Tutor server at $candidateUrl",
            );
            break;
          }
        } catch (_) {}
      }
    }

    bool currentlyOffline = !hasServer;

    if (mounted &&
        (globalIsOffline != currentlyOffline || globalHasServer != hasServer)) {
      setState(() {
        globalIsOffline = currentlyOffline;
        globalHasServer = hasServer;
      });
      if (!globalIsOffline) {
        _syncPendingScores(); // Sync immediately when connection restored
      }
    }

    setState(() {
      debugGlobalIsOffline = globalIsOffline;
      debugGlobalHasServer = globalHasServer;
    });

    print("globalIsOffline = $globalIsOffline");
    print("globalHasServer = $globalHasServer");
  }

  void _initTts() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlayingText = false;
          _currentlyPlayingText = "";
        });
      }
    });
  }

  Future<void> _speakMessage(String text, String lang) async {
    if (_isPlayingText && _currentlyPlayingText == text) {
      await _flutterTts.stop();
      setState(() {
        _isPlayingText = false;
        _currentlyPlayingText = "";
      });
      return;
    }

    if (lang == "mr") {
      await _flutterTts.setLanguage("mr-IN");
    } else if (lang == "hi") {
      await _flutterTts.setLanguage("hi-IN");
    } else {
      await _flutterTts.setLanguage("en-US");
    }

    setState(() {
      _isPlayingText = true;
      _currentlyPlayingText = text;
    });

    await _flutterTts.speak(text);
  }

  Future<void> _loadAllSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _chatSessionIds = prefs.getStringList('chat_session_ids') ?? [];
    });

    if (_chatSessionIds.isNotEmpty) {
      _loadSession(_chatSessionIds.first);
    } else {
      _createNewSession();
    }
  }

  void _createNewSession() async {
    String newId = "Chat Session ${DateTime.now().millisecondsSinceEpoch}";
    setState(() {
      _currentSessionId = newId;
      _messages = [];
      _chatSessionIds.insert(0, newId);
      _villageNotices.shuffle();
      _fetchDynamicChampion();
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('chat_session_ids', _chatSessionIds);
    await prefs.setString(_currentSessionId!, jsonEncode(_messages));

    // Close drawer if open
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  Future<void> _loadSession(String sessionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionData = prefs.getString(sessionId);

    setState(() {
      _currentSessionId = sessionId;
      if (sessionData != null) {
        List<dynamic> decoded = jsonDecode(sessionData);
        _messages = decoded.map((e) => Map<String, String>.from(e)).toList();
      } else {
        _messages = [];
      }
    });

    _scrollToBottom();
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSessionId == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionId!, jsonEncode(_messages));
  }

  Future<void> _deleteSession(String sessionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionId);
    await prefs.remove('name_$sessionId'); // Remove custom name
    setState(() {
      _chatSessionIds.remove(sessionId);
    });
    await prefs.setStringList('chat_session_ids', _chatSessionIds);

    if (_currentSessionId == sessionId) {
      if (_chatSessionIds.isNotEmpty) {
        _loadSession(_chatSessionIds.first);
      } else {
        _createNewSession();
      }
    }
  }

  void _renameSession(String sessionId, String newName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name_$sessionId', newName);
    setState(() {}); // Trigger rebuild to show new name
  }

  void _showRenameDialog(String sessionId, String currentName) {
    TextEditingController renameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Rename Chat"),
          content: TextField(
            controller: renameController,
            decoration: InputDecoration(
              hintText: "Enter new name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (renameController.text.trim().isNotEmpty) {
                  _renameSession(sessionId, renameController.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
          }),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Microphone not available! Make sure you allow permissions.",
            ),
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_controller.text.isNotEmpty) {
        _sendMessage();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndProcessImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() {
      _isTyping = true;
      _messages.add({"role": "user", "text": "[Image Attached]"});
    });
    _scrollToBottom();

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String text = recognizedText.text;
      textRecognizer.close();

      if (text.trim().isEmpty) {
        setState(() {
          _messages.add({
            "role": "bot",
            "text":
                "I couldn't read any text from the image. Please try again with a clearer photo.",
            "lang": "en",
          });
          _isTyping = false;
        });
      } else {
        _controller.text = text;
        _sendMessage();
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "Error processing image: $e",
          "lang": "en",
        });
        _isTyping = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    String query = _controller.text;
    if (query.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add({"role": "user", "text": query});
      _isTyping = true;
    });
    _saveCurrentSession();

    // Increment Mastery Points (XP) and Question Count
    SharedPreferences.getInstance().then((prefs) async {
      int count = prefs.getInt('total_questions') ?? 0;
      int xp = prefs.getInt('total_xp') ?? 0;
      await prefs.setInt('total_questions', count + 1);
      await prefs.setInt('total_xp', xp + 5); // +5 XP for asking/answering

      // Update streak if first activity today
      String lastDate = prefs.getString('last_study_date') ?? "";
      String today =
          "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
      if (lastDate != today) {
        int currentStreak = prefs.getInt('daily_streak') ?? 0;
        await prefs.setInt('daily_streak', currentStreak + 1);
        await prefs.setString('last_study_date', today);
        if (mounted) setState(() => _streakCount = currentStreak + 1);
      }

      _fetchDynamicChampion(); // Refresh champion data
    });

    _scrollToBottom();
    await _flutterTts.stop();

    try {
      bool serverSuccess = false;
      String? onlineAnswer;
      String? detectedLang;

      bool serverAvailable = false;
      setState(() {
        debugLastActionStatus = "Sending using URL: $globalServerUrl";
      });
      print("Sending question using URL = $globalServerUrl");
      try {
        final response = await http
            .get(Uri.parse("$globalServerUrl/health"))
            .timeout(const Duration(seconds: 8));
        print("Health status code = ${response.statusCode}");
        print("Health body = ${response.body}");
        if (response.statusCode == 200 && response.body.contains("ok")) {
          serverAvailable = true;
          setState(() {
            debugLastActionStatus = "Health OK. Sending question /ask...";
            debugLastHealthStatusCode = "${response.statusCode}";
            debugLastHealthResponseBody = response.body.trim();
            debugLastExceptionMessage = "None";
          });
        }
      } catch (e) {
        print("Exception = $e");
        print("Health status: error");
        setState(() {
          debugLastActionStatus = "Health check failed in _sendMessage";
          debugLastExceptionMessage = "$e";
          debugLastHealthStatusCode = "Error";
        });
      }
      print("Offline state: $globalIsOffline");

      if (serverAvailable) {
        try {
          final response = await http
              .post(
                Uri.parse("$globalServerUrl/ask"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({
                  "query": query,
                  "lang": _language,
                  "difficulty": "easy",
                }),
              )
              .timeout(const Duration(seconds: 25));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            onlineAnswer = data["answer"] ?? "No answer received.";
            detectedLang = data["detected_lang"] ?? "en";
            serverSuccess = true;
          }
        } catch (e) {
          print("Exception = $e");
          print("Direct query connection failed: $e");
          setState(() {
            debugLastActionStatus = "Send /ask failed";
            debugLastExceptionMessage = "$e";
          });
        }

        if (serverSuccess && onlineAnswer != null) {
          setState(() {
            _messages.add({
              "role": "bot",
              "text": onlineAnswer!,
              "lang": detectedLang ?? "en",
            });
            _isTyping = false;
            _language = detectedLang ?? "en";
          });

          // Award XP
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int currentChatXP = prefs.getInt('chat_xp_total') ?? 0;
          await prefs.setInt('chat_xp_total', currentChatXP + 5);
          globalUpdateTrigger.add(null);
          return;
        } else {
          setState(() {
            _messages.add({
              "role": "bot",
              "text":
                  "Tutor Error: Health check succeeded but the model failed to respond. Please try again.",
              "lang": "en",
            });
            _isTyping = false;
          });
          return;
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Server unavailable. Using offline glossary."),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
        await _generateOfflineResponse(query);

        // Award XP for Chatting (Offline)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int currentChatXP = prefs.getInt('chat_xp_total') ?? 0;
        await prefs.setInt('chat_xp_total', currentChatXP + 5);

        globalUpdateTrigger.add(null); // Notify dashboard
      }
    } catch (e) {
      print("Chat fallback error: $e");
      await _generateOfflineResponse(query);

      // Award XP for Chatting (Error fallback)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int currentChatXP = prefs.getInt('chat_xp_total') ?? 0;
      await prefs.setInt('chat_xp_total', currentChatXP + 5);
      globalUpdateTrigger.add(null);
    }
  }

  bool _isHindiOrHinglish(String query) {
    if (query.contains(RegExp(r'[\u0900-\u097F]'))) return true;

    final hinglishKeywords = {
      'kya',
      'kaise',
      'kab',
      'kise',
      'kyu',
      'kyon',
      'hai',
      'hain',
      'he',
      'hota',
      'hoti',
      'hote',
      'karta',
      'karti',
      'karne',
      'se',
      'ko',
      'mein',
      'me',
      'par',
      'pe',
      'bhi',
      'aur',
      'ya',
      'kya-hai',
    };

    final words = query.toLowerCase().split(RegExp(r'\s+'));
    for (var w in words) {
      if (hinglishKeywords.contains(w)) return true;
    }
    return false;
  }

  final Map<String, Map<String, String>> _hybridGlossary = {
    "gravity": {
      "hi": "गुरुत्वाकर्षण",
      "rom": "gurutvakarshan",
      "en_def":
          "Gravity is the invisible force that pulls objects toward each other. It is what keeps our feet on the ground and makes things fall when you drop them.",
      "hi_def":
          "गुरुत्वाकर्षण वह अदृश्य बल है जो वस्तुओं को एक-दूसरे की ओर खींचता है। इसी के कारण हम पृथ्वी पर टिके रहते हैं और चीजें नीचे गिरती हैं।",
    },
    "photosynthesis": {
      "hi": "प्रकाश संश्लेषण",
      "rom": "prakash sanshleshan",
      "en_def":
          "Photosynthesis is the process by which green plants and some other organisms use sunlight, water, and carbon dioxide to synthesize nutrients (food), releasing oxygen as a byproduct.",
      "hi_def":
          "प्रकाश संश्लेषण वह प्रक्रिया है जिसके द्वारा हरे पौधे सूर्य के प्रकाश, पानी और कार्बन डाइऑक्साइड का उपयोग करके अपना भोजन बनाते हैं और ऑक्सीजन छोड़ते हैं।",
    },
    "electric": {
      "hi": "विद्युत",
      "rom": "vidyut",
      "en_def":
          "Electric refers to anything related to electricity, which is a form of energy resulting from the flow of charged particles (electrons).",
      "hi_def":
          "विद्युत (इलेक्ट्रिक) का संबंध बिजली से है, जो आवेशित कणों (इलेक्ट्रॉनों) के प्रवाह से उत्पन्न होने वाली ऊर्जा का एक रूप है।",
    },
    "electricity": {
      "hi": "विद्युत",
      "rom": "vidyut",
      "en_def":
          "Electricity is a form of energy resulting from the existence of charged particles (such as electrons or protons), either statically as an accumulation of charge or dynamically as a current.",
      "hi_def":
          "विद्युत ऊर्जा का एक रूप है जो आवेशित कणों (जैसे इलेक्ट्रॉन या प्रोटॉन) की उपस्थिति या उनके प्रवाह के कारण उत्पन्न होता है।",
    },
    "current": {
      "hi": "धारा",
      "rom": "dhara",
      "en_def":
          "Electric current is the rate of flow of electric charge (electrons) through a conducting medium, measured in Amperes.",
      "hi_def":
          "विद्युत धारा किसी चालक में विद्युत आवेश (इलेक्ट्रॉनों) के बहने की दर को कहते हैं, जिसे एम्पियर में मापा जाता है।",
    },
    "pollen": {
      "hi": "पराग",
      "rom": "parag",
      "en_def":
          "Pollen grains are microscopic powder-like grains produced by the male organs of flowers (anthers) that carry sperm cells for plant reproduction.",
      "hi_def":
          "पराग कण फूलों के नर अंग (परागकोष) द्वारा उत्पादित सूक्ष्म पाउडर जैसे कण होते हैं, जो पौधों के प्रजनन में मदद करते हैं।",
    },
    "circle": {
      "hi": "वृत्त",
      "rom": "vritt",
      "en_def":
          "A circle is a round, two-dimensional shape where all points on the curved outer boundary are at an equal distance (radius) from a fixed center point.",
      "hi_def":
          "वृत्त एक गोल, द्वि-आयामी (2D) आकृति है जिसमें घुमावदार बाहरी सीमा के सभी बिंदु एक निश्चित केंद्र बिंदु से समान दूरी (त्रिज्या) पर होते हैं।",
    },
    "prime": {
      "hi": "अभाज्य",
      "rom": "abhajya",
      "en_def":
          "A prime number is a whole number greater than 1 that cannot be formed by multiplying two smaller whole numbers; it has only two factors: 1 and itself (e.g., 2, 3, 5, 7).",
      "hi_def":
          "अभाज्य संख्या 1 से बड़ी वह पूर्ण संख्या होती है जिसके केवल दो ही गुणनखंड होते हैं: 1 और वह स्वयं संख्या (जैसे 2, 3, 5, 7)।",
    },
    "triangle": {
      "hi": "त्रिभुज",
      "rom": "tribhuj",
      "en_def":
          "A triangle is a closed two-dimensional shape with three straight sides, three corners (vertices), and three angles that add up to 180 degrees.",
      "hi_def":
          "त्रिभुज तीन सीधे पक्षों (भुजाओं), तीन कोनों और तीन कोणों वाली एक बंद द्वि-आयामी आकृति है, जिसके तीनों कोणों का योग 180 डिग्री होता है।",
    },
    "area": {
      "hi": "क्षेत्रफल",
      "rom": "kshetrafal",
      "en_def":
          "Area is the measurement of the size or extent of a two-dimensional surface, expressed in square units (like square centimeters or square meters).",
      "hi_def":
          "क्षेत्रफल किसी द्वि-आयामी सतह के आकार या सीमा का माप है, जिसे वर्ग इकाइयों (जैसे वर्ग सेंटीमीटर या वर्ग मीटर) में व्यक्त किया जाता है।",
    },
    "force": {
      "hi": "बल",
      "rom": "bal",
      "en_def":
          "A force is a push or a pull acting upon an object resulting from its interaction with another object. It can change the state of motion or shape of an object (measured in Newtons).",
      "hi_def":
          "बल वह धक्का या खिंचाव है जो किसी वस्तु पर किसी अन्य वस्तु के साथ परस्पर क्रिया के कारण कार्य करता है। यह वस्तु की गति या आकार बदल सकता है।",
    },
    "energy": {
      "hi": "ऊर्जा",
      "rom": "urja",
      "en_def":
          "Energy is the quantitative property that must be transferred to a body or physical system to perform work on, or to heat, the body. It cannot be created or destroyed, only transformed.",
      "hi_def":
          "ऊर्जा कार्य करने या ऊष्मा उत्पन्न करने की क्षमता को कहते हैं। इसे न तो बनाया जा सकता है और न ही नष्ट किया जा सकता है, केवल एक रूप से दूसरे रूप में बदला जा सकता है।",
    },
    "speed": {
      "hi": "गति",
      "rom": "gati",
      "en_def":
          "Speed is the rate at which an object covers distance. It is a scalar quantity calculated by dividing the total distance traveled by the time taken.",
      "hi_def":
          "गति (चाल) वह दर है जिस पर कोई वस्तु दूरी तय करती है। यह कुल तय की गई दूरी को कुल समय से विभाजित करके निकाली जाती है।",
    },
    "velocity": {
      "hi": "वेग",
      "rom": "veg",
      "en_def":
          "Velocity is the speed of an object in a specific direction. It is a vector quantity, meaning it has both magnitude (speed) and direction.",
      "hi_def":
          "वेग किसी निश्चित दिशा में वस्तु की गति को कहते हैं। यह एक सदिश राशि है, जिसका अर्थ है कि इसमें परिमाण (चाल) और दिशा दोनों होते हैं।",
    },
    "acceleration": {
      "hi": "त्वरण",
      "rom": "tvaran",
      "en_def":
          "Acceleration is the rate at which an object's velocity changes over time. It can refer to speeding up, slowing down, or changing direction.",
      "hi_def":
          "त्वरण समय के साथ किसी वस्तु के वेग में होने वाले परिवर्तन की दर को कहते हैं। यह चाल बढ़ने, घटने या दिशा बदलने से संबंधित हो सकता है।",
    },
    "atom": {
      "hi": "परमाणु",
      "rom": "paramanu",
      "en_def":
          "An atom is the basic building block of chemistry and the smallest unit of ordinary matter that forms a chemical element, consisting of protons, neutrons, and electrons.",
      "hi_def":
          "परमाणु किसी भी साधारण पदार्थ की सबसे छोटी इकाई है जो एक रासायनिक तत्व बनाती है, जिसमें प्रोटॉन, न्यूट्रॉन और इलेक्ट्रॉन होते हैं।",
    },
    "molecule": {
      "hi": "अणु",
      "rom": "anu",
      "en_def":
          "A molecule is a group of two or more atoms chemically bonded together, representing the smallest fundamental unit of a chemical compound that can take part in a chemical reaction.",
      "hi_def":
          "अणु रासायनिक रूप से एक साथ बंधे दो या दो से अधिक परमाणुओं का समूह है, जो किसी रासायनिक यौगिक की सबसे छोटी मौलिक इकाई है।",
    },
    "cell": {
      "hi": "कोशिका",
      "rom": "koshika",
      "en_def":
          "A cell is the structural, functional, and biological unit of all living organisms. It is often referred to as the building block of life.",
      "hi_def":
          "कोशिका सभी जीवित जीवों की संरचनात्मक, कार्यात्मक और जैविक इकाई है। इसे अक्सर जीवन की मूल इकाई या ईंट कहा जाता है।",
    },
    "tissue": {
      "hi": "ऊतक",
      "rom": "utak",
      "en_def":
          "A tissue is a group of similar cells working together to perform a specific function in an organism (e.g., muscle tissue, nervous tissue).",
      "hi_def":
          "ऊतक समान कोशिकाओं का एक समूह है जो किसी जीव में एक विशिष्ट कार्य करने के लिए मिलकर काम करता है (जैसे मांसपेशी ऊतक, तंत्रिका ऊतक)।",
    },
    "light": {
      "hi": "प्रकाश",
      "rom": "prakash",
      "en_def":
          "Light is a form of electromagnetic radiation that can be detected by the human eye, traveling in straight lines and enabling us to see the world.",
      "hi_def":
          "प्रकाश विद्युत चुंबकीय विकिरण का एक रूप है जिसे मानव आंख द्वारा देखा जा सकता है, जो सीधी रेखाओं में चलता है और हमें दुनिया को देखने में सक्षम बनाता है।",
    },
    "reflection": {
      "hi": "परावर्तन",
      "rom": "paravartan",
      "en_def":
          "Reflection is the bouncing back of light, sound, or heat waves when they hit a surface that they cannot pass through, like light bouncing off a mirror.",
      "hi_def":
          "परावर्तन प्रकाश, ध्वनि या ऊष्मा तरंगों का किसी सतह से टकराकर वापस लौटने की प्रक्रिया है जिससे वे पार नहीं हो सकतीं (जैसे दर्पण से प्रकाश का टकराकर लौटना)।",
    },
    "refraction": {
      "hi": "अपवर्तन",
      "rom": "apavartan",
      "en_def":
          "Refraction is the bending of light waves as they pass from one transparent medium to another of different density, caused by a change in their speed.",
      "hi_def":
          "अपवर्तन प्रकाश की किरणों के एक पारदर्शी माध्यम से दूसरे भिन्न घनत्व वाले माध्यम में जाने पर मुड़ने की प्रक्रिया है, जो उनकी गति में बदलाव के कारण होती है।",
    },
    "acid": {
      "hi": "अम्ल",
      "rom": "amla",
      "en_def":
          "An acid is a chemical substance that neutralizes alkalis, turns blue litmus paper red, has a sour taste, and has a pH value of less than 7.",
      "hi_def":
          "अम्ल वह रासायनिक पदार्थ है जो क्षारों को उदासीन करता है, नीले लिटमस को लाल करता है, स्वाद में खट्टा होता है, और इसका pH मान 7 से कम होता है।",
    },
    "base": {
      "hi": "क्षार",
      "rom": "kshaar",
      "en_def":
          "A base is a chemical substance that reacts with acids to form salts, turns red litmus paper blue, feels slippery, and has a pH value greater than 7.",
      "hi_def":
          "क्षार वह रासायनिक पदार्थ है जो अम्लों के साथ प्रतिक्रिया करके लवण बनाता है, लाल लिटमस को नीला करता है, और इसका pH मान 7 से अधिक होता है।",
    },
    "metal": {
      "hi": "धातु",
      "rom": "dhatu",
      "en_def":
          "Metals are elements that are typically hard, shiny, malleable, ductile, and good conductors of heat and electricity (e.g., iron, copper, gold).",
      "hi_def":
          "धातु वे तत्व हैं जो आमतौर पर कठोर, चमकदार, आघातवर्धनीय, तन्य और ऊष्मा एवं विद्युत के सुचालक होते हैं (जैसे लोहा, तांबा, सोना)।",
    },
    "nonmetal": {
      "hi": "अधातु",
      "rom": "adhatu",
      "en_def":
          "Nonmetals are elements that lack metallic properties; they are typically poor conductors of heat and electricity, brittle in solid state, and can be gases, liquids, or solids.",
      "hi_def":
          "अधातु वे तत्व हैं जिनमें धात्विक गुण नहीं होते; ये ऊष्मा और विद्युत के कुचालक होते हैं और भंगुर होते हैं (जैसे ऑक्सीजन, कार्बन)।",
    },
    "chemical": {
      "hi": "रासायनिक",
      "rom": "rasayanik",
      "en_def":
          "A chemical is any substance with a distinct molecular composition, produced by or used in a chemical process.",
      "hi_def":
          "रसायन वह पदार्थ है जिसकी एक निश्चित आणविक संरचना होती है, जो किसी रासायनिक प्रक्रिया द्वारा निर्मित या उपयोग की जाती है।",
    },
    "reaction": {
      "hi": "अभिक्रिया",
      "rom": "abhikriya",
      "en_def":
          "A chemical reaction is a process in which one or more substances (reactants) are chemically rearranged and converted into different substances (products).",
      "hi_def":
          "रासायनिक अभिक्रिया वह प्रक्रिया है जिसमें एक या अधिक पदार्थ (अभिकारक) रासायनिक रूप से पुनर्गठित होकर नए पदार्थों (उत्पादों) में परिवर्तित होते हैं।",
    },
    "equation": {
      "hi": "समीकरण",
      "rom": "sameekaran",
      "en_def":
          "A chemical or mathematical equation is a symbolic representation of a relationship, reaction, or equality between two sides (left and right).",
      "hi_def":
          "समीकरण दो पक्षों (बाएं और दाएं) के बीच संबंध, अभिक्रिया या समानता का एक प्रतीकात्मक प्रतिनिधित्व है।",
    },
    "fraction": {
      "hi": "भिन्न",
      "rom": "bhinna",
      "en_def":
          "A fraction represents a part of a whole, consisting of a numerator (top number) and a denominator (bottom number) separated by a dividing line.",
      "hi_def":
          "भिन्न किसी पूर्ण संख्या के एक भाग को दर्शाती है, जिसमें एक अंश (ऊपरी संख्या) और एक हर (निचली संख्या) होती है।",
    },
    "decimal": {
      "hi": "दशमलव",
      "rom": "dashamlav",
      "en_def":
          "A decimal is a fraction written in a special form using a decimal point, based on powers of ten (e.g., 0.5 represents five-tenths).",
      "hi_def":
          "दशमलव 10 की घातों पर आधारित एक संख्या प्रणाली है जिसमें पूर्ण संख्या और उसके अंश को अलग करने के लिए एक बिंदु (दशमलव) का उपयोग किया जाता है।",
    },
    "ratio": {
      "hi": "अनुपात",
      "rom": "anupat",
      "en_def":
          "A ratio is a comparison of two quantities by division, indicating how many times one number contains another (expressed as a:b).",
      "hi_def":
          "अनुपात भाग विधि द्वारा दो मात्राओं की तुलना है, जो यह दर्शाता है कि एक संख्या में दूसरी संख्या कितनी बार शामिल है (a:b)।",
    },
    "proportion": {
      "hi": "समानुपात",
      "rom": "samanupat",
      "en_def":
          "Proportion is an equation that states that two ratios are equal (e.g., a/b = c/d).",
      "hi_def":
          "समानुपात एक समीकरण है जो दर्शाता है कि दो अनुपात आपस में बराबर हैं (जैसे a/b = c/d)।",
    },
    "algebra": {
      "hi": "बीजगणित",
      "rom": "beejganit",
      "en_def":
          "Algebra is a branch of mathematics in which arithmetic relations are generalized using letters or symbols to represent unknown numbers in equations.",
      "hi_def":
          "बीजगणित गणित की वह शाखा है जिसमें अज्ञात संख्याओं को दर्शाने के लिए अक्षरों या प्रतीकों का उपयोग करके समीकरण हल किए जाते हैं।",
    },
    "geometry": {
      "hi": "ज्यामिति",
      "rom": "jyamiti",
      "en_def":
          "Geometry is a branch of mathematics concerned with the properties, measurement, and relationships of points, lines, angles, surfaces, and solids.",
      "hi_def":
          "ज्यामिति गणित की वह शाखा है जो बिंदुओं, रेखाओं, कोणों, सतहों और ठोस पदार्थों के गुणों, माप और उनके संबंधों से संबंधित है।",
    },
    "quadrilateral": {
      "hi": "चतुर्भुज",
      "rom": "chaturbhuj",
      "en_def":
          "A quadrilateral is a flat, two-dimensional geometric shape that has four straight sides, four vertices, and interior angles summing up to 360 degrees.",
      "hi_def":
          "चतुर्भुज चार सीधी भुजाओं और चार कोनों वाली एक बंद द्वि-आयामी आकृति है, जिसके आंतरिक कोणों का योग 360 डिग्री होता है।",
    },
    "rectangle": {
      "hi": "आयात",
      "rom": "aayat",
      "en_def":
          "A rectangle is a four-sided flat shape where all interior angles are right angles (90 degrees) and opposite sides are equal and parallel.",
      "hi_def":
          "आयात चार भुजाओं वाली वह आकृति है जिसके सभी आंतरिक कोण समकोण (90 डिग्री) होते हैं और आमने-सामने की भुजाएं बराबर और समानांतर होती हैं।",
    },
    "square": {
      "hi": "वर्ग",
      "rom": "varg",
      "en_def":
          "A square is a flat shape with four equal straight sides and four right angles (90 degrees).",
      "hi_def":
          "वर्ग चार बराबर सीधी भुजाओं और चार समकोणों (90 डिग्री) वाली एक बंद द्वि-आयामी आकृति है।",
    },
    "number": {
      "hi": "संख्या",
      "rom": "sankhya",
      "en_def":
          "A number is an arithmetical value, expressed by a word, symbol, or figure, representing a particular quantity used in counting and calculating.",
      "hi_def":
          "संख्या एक गणितीय मान है जिसे शब्दों या अंकों द्वारा व्यक्त किया जाता है, जिसका उपयोग गिनती और गणना में होता है।",
    },
    "integer": {
      "hi": "पूर्णांक",
      "rom": "poornank",
      "en_def":
          "An integer is a whole number (not a fractional number) that can be positive, negative, or zero (e.g., -3, 0, 5).",
      "hi_def":
          "पूर्णांक एक पूर्ण संख्या होती है (भिन्न नहीं) जो सकारात्मक, नकारात्मक या शून्य हो सकती है (जैसे -3, 0, 5)।",
    },
    "polynomial": {
      "hi": "बहुपद",
      "rom": "bahupad",
      "en_def":
          "A polynomial is a mathematical expression consisting of variables and coefficients, involving only the operations of addition, subtraction, multiplication, and non-negative integer exponents.",
      "hi_def":
          "बहुपद चर और गुणांकों से बना एक गणितीय व्यंजक है, जिसमें केवल जोड़, घटाव, गुणा और गैर-ऋणात्मक घातें शामिल होती हैं।",
    },
    "trigonometry": {
      "hi": "त्रिकोणमिति",
      "rom": "trikonamiti",
      "en_def":
          "Trigonometry is a branch of mathematics that studies relationships between side lengths and angles of triangles, particularly right-angled triangles.",
      "hi_def":
          "त्रिकोणमिति गणित की वह शाखा है जो त्रिभुजों (विशेषकर समकोण त्रिभुज) की भुजाओं की लंबाई और उनके कोणों के बीच संबंधों का अध्ययन करती।",
    },
    "angle": {
      "hi": "कोण",
      "rom": "kon",
      "en_def":
          "An angle is the space (measured in degrees) between two intersecting lines or surfaces at or close to the point where they meet.",
      "hi_def":
          "कोण दो प्रतिच्छेदी रेखाओं या किरणों के बीच के झुकाव या स्थान को कहते हैं जिसे डिग्री में मापा जाता है।",
    },
    "side": {
      "hi": "भुजा",
      "rom": "bhuja",
      "en_def":
          "A side is a line segment that forms part of the boundary of a geometric shape.",
      "hi_def":
          "भुजा एक रेखा खंड है जो किसी ज्यामितीय आकृति की सीमा का हिस्सा बनाती है।",
    },
    "perimeter": {
      "hi": "परिमाप",
      "rom": "parimap",
      "en_def":
          "Perimeter is the continuous line forming the boundary of a closed geometric shape, calculated by adding the lengths of all its sides.",
      "hi_def":
          "परिमाप किसी बंद ज्यामितीय आकृति की बाहरी सीमा की कुल लंबाई है, जो उसकी सभी भुजाओं के योग के बराबर होती है।",
    },
    "circumference": {
      "hi": "परिधि",
      "rom": "paridhi",
      "en_def":
          "Circumference is the distance around the outer boundary of a circle (its perimeter), calculated using the formula C = 2πr.",
      "hi_def":
          "परिधि किसी वृत्त की बाहरी सीमा की दूरी (उसका परिमाप) को कहते हैं, जिसकी गणना C = 2πr सूत्र से की जाती है।",
    },
    "diameter": {
      "hi": "व्यास",
      "rom": "vyaas",
      "en_def":
          "A diameter is any straight line segment that passes through the center of the circle and whose endpoints lie on the circle, equal to twice the radius.",
      "hi_def":
          "व्यास वह सीधी रेखा है जो वृत्त के केंद्र से होकर गुजरती है और जिसके दोनों सिरे वृत्त पर होते हैं, यह त्रिज्या का दुगुना होता है।",
    },
    "radius": {
      "hi": "त्रिज्या",
      "rom": "trijya",
      "en_def":
          "A radius is a straight line segment from the center of a circle or sphere to its outer boundary or circumference, equal to half of the diameter.",
      "hi_def":
          "त्रिज्या वृत्त या गोले के केंद्र से उसकी बाहरी सीमा तक की दूरी है, जो व्यास की आधी होती है।",
    },
    "volume": {
      "hi": "आयतन",
      "rom": "ayatan",
      "en_def":
          "Volume is the amount of three-dimensional space enclosed by a closed boundary, expressed in cubic units (like cubic centimeters or cubic meters).",
      "hi_def":
          "आयतन किसी त्रि-आयामी (3D) आकृति द्वारा घेरे गए स्थान की मात्रा को कहते हैं, जिसे घन इकाइयों में व्यक्त किया जाता है।",
    },
    "temperature": {
      "hi": "तापमान",
      "rom": "tapmaan",
      "en_def":
          "Temperature is a physical property of matter that quantitatively expresses the hotness or coldness of an object, measured with a thermometer in Celsius, Fahrenheit, or Kelvin.",
      "hi_def":
          "तापमान पदार्थ का वह भौतिक गुण है जो किसी वस्तु के गर्म या ठंडे होने की मात्रा को दर्शाता है, जिसे थर्मामीटर से मापा जाता है।",
    },
    "heat": {
      "hi": "ऊष्मा",
      "rom": "ushma",
      "en_def":
          "Heat is the transfer of kinetic energy from one medium or object to another due to a difference in temperature, flowing from hotter to cooler bodies.",
      "hi_def":
          "ऊष्मा तापमान में अंतर के कारण एक माध्यम या वस्तु से दूसरी वस्तु में स्थानांतरित होने वाली ऊर्जा का एक रूप है जो गर्म से ठंडी वस्तु की ओर बहती है।",
    },
    "pressure": {
      "hi": "दबाव",
      "rom": "dabaab",
      "en_def":
          "Pressure is the force applied perpendicular to the surface of an object per unit area over which that force is distributed (measured in Pascals).",
      "hi_def":
          "दबाव किसी वस्तु की सतह के प्रति इकाई क्षेत्रफल पर लंबवत लगाया गया बल है।",
    },
    "sound": {
      "hi": "ध्वनि",
      "rom": "dhwani",
      "en_def":
          "Sound is a vibration that propagates as an acoustic wave through a transmission medium such as a gas, liquid or solid.",
      "hi_def":
          "ध्वनि कंपन का वह रूप है जो किसी माध्यम (गैस, द्रव या ठोस) में तरंगों के रूप में गमन करता है और हमारे कानों को सुनाई देता है।",
    },
    "magnet": {
      "hi": "चुंबक",
      "rom": "chumbak",
      "en_def":
          "A magnet is an object or material that produces a magnetic field, attracting iron and other magnetic materials and having north and south poles.",
      "hi_def":
          "चुंबक वह वस्तु या पदार्थ है जो चुंबकीय क्षेत्र उत्पन्न करता है, लोहे जैसी चुंबकीय वस्तुओं को आकर्षित करता है और जिसके उत्तरी और दक्षिणी ध्रुव होते हैं।",
    },
    "plants": {
      "hi": "पौधे",
      "rom": "paudhe",
      "en_def":
          "Plants are multicellular living organisms belonging to the kingdom Plantae, characterized by photosynthesis and cell walls containing cellulose.",
      "hi_def":
          "पौधे बहुकोशिकीय जीवित जीव हैं जो पादप जगत के अंतर्गत आते हैं, जो प्रकाश संश्लेषण की क्रिया द्वारा अपना भोजन स्वयं बनाते हैं।",
    },
    "food": {
      "hi": "भोजन",
      "rom": "bhojan",
      "en_def":
          "Food is any nutritious substance that people or animals eat or drink, or that plants absorb, in order to maintain life and growth.",
      "hi_def":
          "भोजन वह पौष्टिक पदार्थ है जिसे जीव जीवन बनाए रखने, ऊर्जा प्राप्त करने और वृद्धि के लिए खाते, पीते या अवशोषित करते हैं।",
    },
  };

  final Map<String, List<String>> _crossLangSynonyms = {};

  void _initializeGlossaryAndSynonyms() {
    _crossLangSynonyms.clear();
    _hybridGlossary.forEach((englishKey, translations) {
      String hi = translations["hi"] ?? "";
      String rom = translations["rom"] ?? "";

      List<String> list = [englishKey, hi, rom];
      list.removeWhere((element) => element.isEmpty);

      for (var item in list) {
        final lowerItem = item.toLowerCase();
        _crossLangSynonyms[lowerItem] = list
            .where((element) => element.toLowerCase() != lowerItem)
            .toList();
      }
    });
  }

  Future<void> _generateOfflineResponse(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String manifestStr = prefs.getString('library_manifest') ?? "{}";
    Map<String, dynamic> manifest = jsonDecode(manifestStr);

    List<String> allChunks = [];
    manifest.forEach((key, value) {
      allChunks.addAll(List<String>.from(value));
    });

    bool isHindiQuery = _isHindiOrHinglish(query);

    if (allChunks.isEmpty) {
      // If manifest is empty, try glossary directly as a last resort!
      String glossaryKey = "";
      String glossaryEnDef = "";
      String glossaryHiDef = "";
      String hiKeyword = "";

      for (var entry in _hybridGlossary.entries) {
        String engKey = entry.key;
        String hiVal = entry.value["hi"] ?? "";
        String romVal = entry.value["rom"] ?? "";
        final lowerQuery = query.toLowerCase();
        if (lowerQuery.contains(engKey) ||
            lowerQuery.contains(hiVal) ||
            lowerQuery.contains(romVal)) {
          glossaryKey = engKey;
          hiKeyword = hiVal;
          glossaryEnDef = entry.value["en_def"] ?? "";
          glossaryHiDef = entry.value["hi_def"] ?? "";
          break;
        }
      }

      if (glossaryKey.isNotEmpty && glossaryEnDef.isNotEmpty) {
        String answer = "";
        String respLang = "en";
        if (!isHindiQuery) {
          answer = glossaryEnDef;
          respLang = "en";
        } else {
          String topicLabel =
              "${glossaryKey.substring(0, 1).toUpperCase()}${glossaryKey.substring(1)} / $hiKeyword";
          Map<String, String> bilingualData = {
            "type": "bilingual",
            "topic": topicLabel,
            "en": glossaryEnDef,
            "hi": glossaryHiDef.isNotEmpty ? glossaryHiDef : hiKeyword,
          };
          answer = jsonEncode(bilingualData);
          respLang = "hybrid";
        }

        setState(() {
          _messages.add({
            "role": "bot",
            "text": answer,
            "lang": respLang,
            "offline": "true",
          });
          _isTyping = false;
        });
        _scrollToBottom();
        return;
      }

      setState(() {
        _messages.add({
          "role": "bot",
          "text": isHindiQuery
              ? "आप वर्तमान में ऑफ़लाइन हैं, और आपकी ऑफ़लाइन लाइब्रेरी खाली है। कृपया ऑफ़लाइन सहायता के लिए एनसीईआरटी पुस्तकों को डाउनलोड करने के लिए इंटरनेट से जुड़ें।"
              : "You are currently offline, and your Offline Library is empty. Please connect to the internet to download NCERT books for offline assistance.",
          "lang": isHindiQuery ? "hi" : "en",
        });
        _isTyping = false;
      });
      return;
    }

    // Tokenize query
    List<String> words = query.toLowerCase().split(RegExp(r'\s+'));
    String bestMatch = "";
    int maxScore = 0;

    for (var chunk in allChunks) {
      int score = 0;
      final chunkLower = chunk.toLowerCase();
      bool chunkIsHindi = chunk.contains(RegExp(r'[\u0900-\u097F]'));

      // Language alignment boost
      if (isHindiQuery == chunkIsHindi) {
        score += 2;
      }

      for (var word in words) {
        if (word.length > 2) {
          // Direct match
          if (chunkLower.contains(word)) {
            score += 3;
          } else {
            // Check synonyms
            final synonyms = _crossLangSynonyms[word];
            if (synonyms != null) {
              for (var syn in synonyms) {
                if (chunkLower.contains(syn.toLowerCase())) {
                  score += 2;
                  break;
                }
              }
            }
          }
        }
      }
      if (score > maxScore) {
        maxScore = score;
        bestMatch = chunk;
      }
    }

    // Extract matching glossary term for bilingual pairing
    String matchedEnglishKey = "";
    String hiKeyword = "";
    String glossaryEnDef = "";
    String glossaryHiDef = "";

    for (var entry in _hybridGlossary.entries) {
      String engKey = entry.key;
      String hiVal = entry.value["hi"] ?? "";
      String romVal = entry.value["rom"] ?? "";

      final lowerQuery = query.toLowerCase();
      final lowerMatch = bestMatch.toLowerCase();

      if (lowerQuery.contains(engKey) ||
          lowerQuery.contains(hiVal) ||
          lowerQuery.contains(romVal)) {
        matchedEnglishKey = engKey;
        hiKeyword = hiVal;
        glossaryEnDef = entry.value["en_def"] ?? "";
        glossaryHiDef = entry.value["hi_def"] ?? "";
        break;
      }
    }

    String answer = "";
    String respLang = "en";
    String vocabString = "";

    // Extract matching vocabulary terms
    List<String> vocabList = [];
    for (var entry in _hybridGlossary.entries) {
      String engKey = entry.key;
      String hiVal = entry.value["hi"] ?? "";
      String romVal = entry.value["rom"] ?? "";

      final lowerQuery = query.toLowerCase();
      if (lowerQuery.contains(engKey) ||
          lowerQuery.contains(hiVal) ||
          lowerQuery.contains(romVal)) {
        String capEng =
            "${engKey.substring(0, 1).toUpperCase()}${engKey.substring(1)}";
        vocabList.add("$capEng = $hiVal ($romVal)");
      }
    }
    if (vocabList.isNotEmpty) {
      vocabString = vocabList.join(";");
    }

    if (maxScore > 2) {
      String enChunk = "";
      String hiChunk = "";

      bool bestMatchIsHindi = bestMatch.contains(RegExp(r'[\u0900-\u097F]'));
      if (bestMatchIsHindi) {
        hiChunk = bestMatch;
      } else {
        enChunk = bestMatch;
      }

      // Search for the counterpart in allChunks
      if (matchedEnglishKey.isNotEmpty) {
        for (var chunk in allChunks) {
          bool isHindi = chunk.contains(RegExp(r'[\u0900-\u097F]'));
          if (isHindi && hiChunk.isEmpty) {
            if (chunk.toLowerCase().contains(hiKeyword.toLowerCase()) ||
                chunk.toLowerCase().contains(matchedEnglishKey.toLowerCase())) {
              hiChunk = chunk;
            }
          } else if (!isHindi && enChunk.isEmpty) {
            if (chunk.toLowerCase().contains(matchedEnglishKey.toLowerCase())) {
              enChunk = chunk;
            }
          }
        }
      }

      // Fill missing counterpart with glossary definition as fallback
      if (matchedEnglishKey.isNotEmpty) {
        if (enChunk.isEmpty && glossaryEnDef.isNotEmpty)
          enChunk = glossaryEnDef;
        if (hiChunk.isEmpty && glossaryHiDef.isNotEmpty)
          hiChunk = glossaryHiDef;
      }

      if (!isHindiQuery) {
        // English query -> return ONLY English
        respLang = "en";
        if (enChunk.isNotEmpty) {
          answer = enChunk;
        } else if (!bestMatchIsHindi) {
          answer = bestMatch;
        } else {
          answer = glossaryEnDef.isNotEmpty
              ? glossaryEnDef
              : "Found a topic reference in Offline Library:\n\n$bestMatch";
        }
      } else {
        // Hindi/Hinglish query -> return bilingual tabbed card
        if (enChunk.isNotEmpty && hiChunk.isNotEmpty) {
          String topicLabel = matchedEnglishKey.isNotEmpty
              ? "${matchedEnglishKey.substring(0, 1).toUpperCase()}${matchedEnglishKey.substring(1)} / $hiKeyword"
              : "Topic Reference / विषय संदर्भ";

          Map<String, String> bilingualData = {
            "type": "bilingual",
            "topic": topicLabel,
            "en": enChunk,
            "hi": hiChunk,
          };
          answer = jsonEncode(bilingualData);
          respLang = "hybrid";
        } else {
          respLang = bestMatchIsHindi ? "hi" : "en";
          answer = bestMatchIsHindi
              ? "आपकी ऑफ़लाइन लाइब्रेरी में यह मिला:\n\n$bestMatch"
              : "Found this in your Offline Library:\n\n$bestMatch";
        }
      }
    } else {
      // Check if query matched a glossary term (Safety Net Fallback)
      if (matchedEnglishKey.isNotEmpty && glossaryEnDef.isNotEmpty) {
        if (!isHindiQuery) {
          respLang = "en";
          answer = glossaryEnDef;
        } else {
          String topicLabel =
              "${matchedEnglishKey.substring(0, 1).toUpperCase()}${matchedEnglishKey.substring(1)} / $hiKeyword";
          Map<String, String> bilingualData = {
            "type": "bilingual",
            "topic": topicLabel,
            "en": glossaryEnDef,
            "hi": glossaryHiDef.isNotEmpty ? glossaryHiDef : hiKeyword,
          };
          answer = jsonEncode(bilingualData);
          respLang = "hybrid";
        }
      } else {
        respLang = isHindiQuery ? "hi" : "en";
        answer = isHindiQuery
            ? "मैं अभी ऑफ़लाइन हूँ और आपकी लाइब्रेरी में कोई सीधा मेल नहीं मिला। कृपया अपने डाउनलोड किए गए विज्ञान या गणित के विषयों (जैसे gravity, circle, photosynthesis) के बारे में पूछें!"
            : "I'm offline right now and couldn't find a direct match in your library. Try asking about Science or Math topics you've downloaded (like gravity, circle, photosynthesis)!";
      }
    }

    setState(() {
      final msgMap = {"role": "bot", "text": answer, "lang": respLang};
      if (vocabString.isNotEmpty) {
        msgMap["vocabulary"] = vocabString;
      }
      _messages.add(msgMap);
      _isTyping = false;
      _language = isHindiQuery ? "hi" : "en";
    });
    _saveCurrentSession();
    _scrollToBottom();
  }

  // NEW: Robust Offline Flashcard System
  final List<Map<String, String>> _offlineFlashcards = [
    {
      "title": "Science: Gravity",
      "content":
          "Gravity is the force that pulls objects toward each other. On Earth, gravity pulls everything toward the center of the planet.",
    },
    {
      "title": "Math: Prime Numbers",
      "content":
          "A prime number is a number greater than 1 that has no positive divisors other than 1 and itself (e.g., 2, 3, 5, 7).",
    },
    {
      "title": "English: Nouns",
      "content":
          "A noun is a word that represents a person, place, thing, or idea. Examples: Teacher, Village, Book, Happiness.",
    },
    {
      "title": "History: Independence",
      "content":
          "India gained independence from British rule on August 15, 1947, marking a new era for the nation.",
    },
    {
      "title": "Science: Photosynthesis",
      "content":
          "Plants make their own food using sunlight, water, and carbon dioxide through a process called photosynthesis.",
    },
    {
      "title": "GK: Solar System",
      "content":
          "The Sun is the center of our solar system, and eight planets (like Earth and Mars) revolve around it.",
    },
    {
      "title": "English: Verbs",
      "content":
          "Verbs are action words. They describe what someone is doing. Examples: Run, Study, Learn, Help.",
    },
    {
      "title": "Math: Right Angle",
      "content":
          "A right angle is exactly 90 degrees. You can find them at the corners of squares and rectangles.",
    },
    {
      "title": "Science: Water Cycle",
      "content":
          "Water moves from the earth to the sky and back again in a process called the water cycle (Evaporation, Condensation, Precipitation).",
    },
    {
      "title": "Health: Balanced Diet",
      "content":
          "Eating a variety of foods like fruits, vegetables, grains, and proteins helps your body grow strong and healthy.",
    },
    {
      "title": "Science: Atom",
      "content":
          "Everything in the world is made of tiny particles called atoms. They are too small to see with just your eyes!",
    },
    {
      "title": "Math: Pi (π)",
      "content":
          "Pi is the ratio of a circle's circumference to its diameter. It is roughly 3.14 and never ends!",
    },
    {
      "title": "English: Adjectives",
      "content":
          "Adjectives describe nouns. Examples: 'The *blue* sky', 'The *fast* car', 'The *kind* teacher'.",
    },
    {
      "title": "GK: Seven Wonders",
      "content":
          "The Taj Mahal in India is one of the Seven Wonders of the World. It was built using white marble.",
    },
    {
      "title": "Science: States of Matter",
      "content":
          "Matter exists in three main states: Solid (ice), Liquid (water), and Gas (steam).",
    },
  ];

  void _showFlashcardsDialog() async {
    // Randomize and pick 5 cards for the day
    List<Map<String, String>> dailyCards = (List<Map<String, String>>.from(
      _offlineFlashcards,
    )..shuffle()).take(5).toList();
    int currentIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF5F7FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Daily Discovery (${currentIndex + 1}/5)",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ),
                ],
              ),
              content: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 250,
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dailyCards[currentIndex]["title"]!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          dailyCards[currentIndex]["content"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (currentIndex < dailyCards.length - 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () => setModalState(() => currentIndex++),
                      child: const Text(
                        "NEXT FACT →",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        int xp = prefs.getInt('total_xp') ?? 0;
                        await prefs.setInt('total_xp', xp + 50);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "🎉 Mastery Points +50! Keep growing.",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text(
                        "CLAIM XP & FINISH",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettingsDialog() {
    TextEditingController urlController = TextEditingController(
      text: globalServerUrl,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "⚙️ Configuration",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: "Backend URL",
              hintText: "http://IP:PORT",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String url = urlController.text.trim();
                if (url.isNotEmpty) {
                  if (!url.startsWith("http://") &&
                      !url.startsWith("https://")) {
                    url = "http://$url";
                  }
                  while (url.endsWith("/")) {
                    url = url.substring(0, url.length - 1);
                  }
                }
                setState(() {
                  globalServerUrl = url;
                });
                await prefs.setString('global_server_url', url);
                Navigator.pop(context);
                _checkNetwork(null); // Re-check immediately
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg) {
    bool isUser = msg["role"] == "user";
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.indigoAccent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            msg["text"]!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // Bot message processing
    String text = msg["text"] ?? "";
    bool isBilingual = false;
    Map<String, dynamic> bilingualData = {};
    try {
      if (text.startsWith("{") && text.endsWith("}")) {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded["type"] == "bilingual") {
          isBilingual = true;
          bilingualData = Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    if (isBilingual) {
      return BilingualMessageBubble(
        topic: bilingualData["topic"] ?? "Offline Reference",
        enText: bilingualData["en"] ?? "",
        hiText: bilingualData["hi"] ?? "",
        onSpeak: (t, l) => _speakMessage(t, l),
        isPlaying: _isPlayingText,
        currentlyPlayingText: _currentlyPlayingText,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            if (msg["vocabulary"] != null && msg["vocabulary"]!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Key Vocabulary (महत्वपूर्ण शब्द):",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: msg["vocabulary"]!.split(";").map((term) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      term,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _speakMessage(text, msg["lang"] ?? "en"),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (_isPlayingText && _currentlyPlayingText == text)
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (_isPlayingText && _currentlyPlayingText == text)
                          ? "Stop Reading"
                          : "Read Aloud",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 40,
                          width: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "GramNet AI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hello, $_userName!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "AI-Powered Smart Village Assistance System for Education",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Chat History",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "New Chat",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close drawer
                      _createNewSession();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _chatSessionIds.isEmpty
                  ? const Center(
                      child: Text(
                        "No history yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _chatSessionIds.length,
                      itemBuilder: (context, index) {
                        String sessionId = _chatSessionIds[index];
                        bool isSelected = sessionId == _currentSessionId;

                        return FutureBuilder<SharedPreferences>(
                          future: SharedPreferences.getInstance(),
                          builder: (context, snapshot) {
                            String readableName =
                                "Chat Session ${_chatSessionIds.length - index}";
                            if (snapshot.hasData) {
                              String? customName = snapshot.data!.getString(
                                'name_$sessionId',
                              );
                              if (customName != null && customName.isNotEmpty) {
                                readableName = customName;
                              } else {
                                try {
                                  int ts = int.parse(sessionId.split(" ").last);
                                  DateTime dt =
                                      DateTime.fromMillisecondsSinceEpoch(ts);
                                  readableName =
                                      "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
                                } catch (e) {}
                              }
                            }

                            return ListTile(
                              leading: Icon(
                                Icons.chat_bubble_outline,
                                color: isSelected ? Colors.indigo : Colors.grey,
                              ),
                              title: Text(
                                readableName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.indigo.withOpacity(0.1),
                              onTap: () {
                                Navigator.pop(context);
                                _loadSession(sessionId);
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    onPressed: () => _showRenameDialog(
                                      sessionId,
                                      readableName,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteSession(sessionId),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text(
              "GramNet AI",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Connection Status Indicator (Online / Offline)
          IconButton(
            icon: Icon(
              globalIsOffline
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_done_rounded,
              color: globalIsOffline
                  ? Colors.redAccent.shade100
                  : Colors.greenAccent.shade400,
              size: 28,
            ),
            tooltip: globalIsOffline
                ? "Offline Mode (Tap to Auto-Detect / Reconnect)"
                : "Online Mode (Tap to Force Offline)",
            onPressed: () {
              setState(() {
                globalIsManualOffline = !globalIsManualOffline;
                if (globalIsManualOffline) {
                  globalIsOffline = true;
                } else {
                  _checkNetwork(null);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    globalIsManualOffline
                        ? "Forced Offline Mode (Using Phone's Local Library)"
                        : "Auto-Detecting Connection...",
                  ),
                  backgroundColor: globalIsManualOffline
                      ? Colors.redAccent
                      : Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _language,
              dropdownColor: Colors.indigo,
              icon: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
              underline: Container(),
              items: ["en", "hi", "mr"]
                  .map(
                    (l) => DropdownMenuItem(
                      value: l,
                      child: Text(
                        l.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() {
                _language = val!;
              }),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
            tooltip: "Server Settings",
          ),
        ],
        elevation: 8,
        shadowColor: Colors.indigo.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Network Debug Panel UI
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "🔌 CONNECTION DEBUG PANEL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.orange,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _checkNetwork(null);
                        debugRawHttp();
                      },
                      child: const Text(
                        "Ping /health",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "globalServerUrl: $debugGlobalServerUrl",
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "globalIsOffline: $debugGlobalIsOffline | globalHasServer: $debugGlobalHasServer",
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                Text(
                  "Last Status: $debugLastHealthStatusCode | Last Response: $debugLastHealthResponseBody",
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                Text(
                  "Last Action: $debugLastActionStatus",
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                Text(
                  "Last Exception: $debugLastExceptionMessage",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$_streakCount DAY STREAK",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildOfflineToolbox(), // NEW: Offline Toolbox
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              size: 80,
                              color: Colors.indigo.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            t("tutor_ready"),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t("tap_mic"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Village Champion Card (DYNAMIC)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.stars_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t("village_champion"),
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          _championName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Class $_championClass • $_championXP",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Flashcards / Daily Revision Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: InkWell(
                              onTap: _showFlashcardsDialog,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade400,
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.bolt,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t("daily_revision"),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            "Learn 5 quick facts & earn XP",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Village Notice Board
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.shade100,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.campaign,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      t("notice_board"),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _villageNotices.length,
                                    itemBuilder: (context, i) => Padding(
                                      padding: const EdgeInsets.only(right: 32),
                                      child: Center(
                                        child: Text(
                                          _villageNotices[i],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 10),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.indigo,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Tutor is thinking...",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                            onPressed: _listen,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.grey[600],
                            ),
                            onPressed: _pickAndProcessImage,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: "Type your question here...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.indigo, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(12),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDashboardStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildXPBar() {
    int lvl = (_streakCount * 10) ~/ 100 + 1;
    double progress = (_streakCount * 10 % 100) / 100;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Lvl $lvl",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              "${(_streakCount * 10) % 100}/100 XP",
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.indigo.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation(Colors.amber),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildOfflineToolbox() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SCHOLASTIC KNOWLEDGE VAULT",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.indigo,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolIcon(
                Icons.calculate_rounded,
                "Formulas",
                Colors.blue,
                _showFormulaVault,
              ),
              _buildToolIcon(
                Icons.spellcheck_rounded,
                "Glossary",
                Colors.green,
                _showScienceGlossary,
              ),
              _buildToolIcon(
                Icons.workspace_premium_rounded,
                "Medals",
                Colors.amber,
                _showMedalGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showFormulaVault() {
    String selectedCategory = "All";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<Map<String, String>> formulas = [
              // --- MATHEMATICS ---
              {
                "name": "Perimeter of a Rectangle",
                "formula": "P = 2 × (l + b)",
                "category": "Mathematics",
              },
              {
                "name": "Area of a Rectangle",
                "formula": "A = l × b",
                "category": "Mathematics",
              },
              {
                "name": "Perimeter of a Square",
                "formula": "P = 4 × s",
                "category": "Mathematics",
              },
              {
                "name": "Area of a Square",
                "formula": "A = s²",
                "category": "Mathematics",
              },
              {
                "name": "Area of a Triangle",
                "formula": "A = ½ × b × h",
                "category": "Mathematics",
              },
              {
                "name": "Circumference of a Circle",
                "formula": "C = 2πr",
                "category": "Mathematics",
              },
              {
                "name": "Area of a Circle",
                "formula": "A = πr²",
                "category": "Mathematics",
              },
              {
                "name": "Area of a Parallelogram",
                "formula": "A = b × h",
                "category": "Mathematics",
              },
              {
                "name": "Pythagoras Theorem",
                "formula": "a² + b² = c²",
                "category": "Mathematics",
              },
              {
                "name": "Heron\'s Formula",
                "formula": "Area = √[s(s-a)(s-b)(s-c)] where s = (a+b+c)/2",
                "category": "Mathematics",
              },
              {
                "name": "Total Surface Area of a Cube",
                "formula": "TSA = 6a²",
                "category": "Mathematics",
              },
              {
                "name": "Lateral Surface Area of a Cube",
                "formula": "LSA = 4a²",
                "category": "Mathematics",
              },
              {
                "name": "Volume of a Cube",
                "formula": "V = a³",
                "category": "Mathematics",
              },
              {
                "name": "Total Surface Area of a Cuboid",
                "formula": "TSA = 2(lb + bh + hl)",
                "category": "Mathematics",
              },
              {
                "name": "Lateral Surface Area of a Cuboid",
                "formula": "LSA = 2h(l + b)",
                "category": "Mathematics",
              },
              {
                "name": "Volume of a Cuboid",
                "formula": "V = l × b × h",
                "category": "Mathematics",
              },
              {
                "name": "Curved Surface Area of a Cylinder",
                "formula": "CSA = 2πrh",
                "category": "Mathematics",
              },
              {
                "name": "Total Surface Area of a Cylinder",
                "formula": "TSA = 2πr(r + h)",
                "category": "Mathematics",
              },
              {
                "name": "Volume of a Cylinder",
                "formula": "V = πr²h",
                "category": "Mathematics",
              },
              {
                "name": "Curved Surface Area of a Cone",
                "formula": "CSA = πrl where l = √(r² + h²)",
                "category": "Mathematics",
              },
              {
                "name": "Total Surface Area of a Cone",
                "formula": "TSA = πr(l + r)",
                "category": "Mathematics",
              },
              {
                "name": "Volume of a Cone",
                "formula": "V = ⅓πr²h",
                "category": "Mathematics",
              },
              {
                "name": "Surface Area of a Sphere",
                "formula": "A = 4πr²",
                "category": "Mathematics",
              },
              {
                "name": "Volume of a Sphere",
                "formula": "V = ⁴/₃πr³",
                "category": "Mathematics",
              },
              {
                "name": "Curved Surface Area of a Hemisphere",
                "formula": "CSA = 2πr²",
                "category": "Mathematics",
              },
              {
                "name": "Total Surface Area of a Hemisphere",
                "formula": "TSA = 3πr²",
                "category": "Mathematics",
              },
              {
                "name": "Volume of a Hemisphere",
                "formula": "V = ⅔πr³",
                "category": "Mathematics",
              },
              {
                "name": "Area of a Sector of a Circle",
                "formula": "A = (θ / 360) × πr²",
                "category": "Mathematics",
              },
              {
                "name": "Length of an Arc of a Sector",
                "formula": "l = (θ / 360) × 2πr",
                "category": "Mathematics",
              },
              {
                "name": "Linear Equation Standard Form",
                "formula": "ax + b = 0",
                "category": "Mathematics",
              },
              {
                "name": "Quadratic Formula",
                "formula": "x = [-b ± √(b² - 4ac)] / 2a",
                "category": "Mathematics",
              },
              {
                "name": "Discriminant of a Quadratic Equation",
                "formula": "D = b² - 4ac",
                "category": "Mathematics",
              },
              {
                "name": "Arithmetic Progression (nth Term)",
                "formula": "an = a + (n - 1)d",
                "category": "Mathematics",
              },
              {
                "name": "Arithmetic Progression (Sum of n Terms)",
                "formula": "Sn = n/2 [2a + (n - 1)d]",
                "category": "Mathematics",
              },
              {
                "name": "Distance Formula",
                "formula": "d = √[(x₂ - x₁)² + (y₂ - y₁)²]",
                "category": "Mathematics",
              },
              {
                "name": "Section Formula (Internal Division)",
                "formula":
                    "P(x, y) = ((m₁x₂ + m₂x₁)/(m₁ + m₂), (m₁y₂ + m₂y₁)/(m₁ + m₂))",
                "category": "Mathematics",
              },
              {
                "name": "Midpoint Formula",
                "formula": "P(x, y) = ((x₁ + x₂)/2, (y₁ + y₂)/2)",
                "category": "Mathematics",
              },
              {
                "name": "Trigonometric Identity 1",
                "formula": "sin²θ + cos²θ = 1",
                "category": "Mathematics",
              },
              {
                "name": "Trigonometric Identity 2",
                "formula": "1 + tan²θ = sec²θ",
                "category": "Mathematics",
              },
              {
                "name": "Trigonometric Identity 3",
                "formula": "1 + cot²θ = cosec²θ",
                "category": "Mathematics",
              },
              {
                "name": "Class Mark",
                "formula": "Class Mark = (Upper Limit + Lower Limit) / 2",
                "category": "Mathematics",
              },
              {
                "name": "Probability of an Event",
                "formula": "P(E) = Outcomes (Fav) / Outcomes (Total)",
                "category": "Mathematics",
              },
              {
                "name": "Empirical Formula (Statistics)",
                "formula": "3 × Median = Mode + 2 × Mean",
                "category": "Mathematics",
              },

              // --- PHYSICS ---
              {
                "name": "Speed / Velocity",
                "formula": "v = d / t",
                "category": "Physics",
              },
              {
                "name": "Average Speed",
                "formula": "Avg Speed = Total Distance / Total Time",
                "category": "Physics",
              },
              {
                "name": "Acceleration",
                "formula": "a = (v - u) / t",
                "category": "Physics",
              },
              {
                "name": "First Equation of Motion",
                "formula": "v = u + at",
                "category": "Physics",
              },
              {
                "name": "Second Equation of Motion",
                "formula": "s = ut + ½at²",
                "category": "Physics",
              },
              {
                "name": "Third Equation of Motion",
                "formula": "v² - u² = 2as",
                "category": "Physics",
              },
              {
                "name": "Momentum",
                "formula": "p = m × v",
                "category": "Physics",
              },
              {
                "name": "Newton\'s Second Law",
                "formula": "F = m × a",
                "category": "Physics",
              },
              {
                "name": "Universal Gravitation",
                "formula": "F = G(m₁m₂) / d²",
                "category": "Physics",
              },
              {
                "name": "Acceleration due to Gravity",
                "formula": "g = GM / R²",
                "category": "Physics",
              },
              {"name": "Weight", "formula": "W = m × g", "category": "Physics"},
              {
                "name": "Density",
                "formula": "ρ = m / V",
                "category": "Physics",
              },
              {
                "name": "Thrust and Pressure",
                "formula": "P = F / A",
                "category": "Physics",
              },
              {
                "name": "Relative Density",
                "formula": "Rel Density = Density (Sub) / Density (H₂O)",
                "category": "Physics",
              },
              {
                "name": "Work Done",
                "formula": "W = F × s × cosθ",
                "category": "Physics",
              },
              {
                "name": "Kinetic Energy",
                "formula": "KE = ½mv²",
                "category": "Physics",
              },
              {
                "name": "Potential Energy",
                "formula": "PE = mgh",
                "category": "Physics",
              },
              {"name": "Power", "formula": "P = W / t", "category": "Physics"},
              {
                "name": "Commercial Unit of Electrical Energy",
                "formula": "1 kWh = 3.6 × 10⁶ J",
                "category": "Physics",
              },
              {
                "name": "Einstein\'s Mass-Energy Relation",
                "formula": "E = mc²",
                "category": "Physics",
              },
              {
                "name": "Frequency",
                "formula": "f = 1 / T",
                "category": "Physics",
              },
              {
                "name": "Wave Speed",
                "formula": "v = f × λ",
                "category": "Physics",
              },
              {
                "name": "Mirror Formula",
                "formula": "1/f = 1/v + 1/u",
                "category": "Physics",
              },
              {
                "name": "Magnification of Mirror",
                "formula": "m = -v / u = h_i / h_o",
                "category": "Physics",
              },
              {
                "name": "Refractive Index",
                "formula": "n = c / v",
                "category": "Physics",
              },
              {
                "name": "Snell\'s Law",
                "formula": "sin i / sin r = constant (n₂₁)",
                "category": "Physics",
              },
              {
                "name": "Lens Formula",
                "formula": "1/f = 1/v - 1/u",
                "category": "Physics",
              },
              {
                "name": "Magnification of Lens",
                "formula": "m = v / u = h_i / h_o",
                "category": "Physics",
              },
              {
                "name": "Power of a Lens",
                "formula": "P = 1 / f (in meters)",
                "category": "Physics",
              },
              {
                "name": "Electric Current",
                "formula": "I = Q / t",
                "category": "Physics",
              },
              {
                "name": "Electric Potential / Potential Difference",
                "formula": "V = W / Q",
                "category": "Physics",
              },
              {
                "name": "Ohm\'s Law",
                "formula": "V = I × R",
                "category": "Physics",
              },
              {
                "name": "Resistance",
                "formula": "R = ρ(l / A)",
                "category": "Physics",
              },
              {
                "name": "Resistance in Series",
                "formula": "R_s = R₁ + R₂ + R₃",
                "category": "Physics",
              },
              {
                "name": "Resistance in Parallel",
                "formula": "1/R_p = 1/R₁ + 1/R₂ + 1/R₃",
                "category": "Physics",
              },
              {
                "name": "Joule\'s Law of Heating",
                "formula": "H = I²Rt",
                "category": "Physics",
              },
              {
                "name": "Electric Power",
                "formula": "P = V × I = I²R = V² / R",
                "category": "Physics",
              },

              // --- CHEMISTRY ---
              {
                "name": "pH Scale Relation",
                "formula": "pH = -log[H⁺]",
                "category": "Chemistry",
              },
            ];

            final filteredFormulas = selectedCategory == "All"
                ? formulas
                : formulas
                      .where((f) => f["category"] == selectedCategory)
                      .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        color: Colors.indigo,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Formula Vault 📐",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ["All", "Mathematics", "Physics", "Chemistry"]
                          .map((category) {
                            bool isSelected = selectedCategory == category;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedCategory = category;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.indigo
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.indigo
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.indigo.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredFormulas.isEmpty
                        ? const Center(child: Text("No formulas found"))
                        : ListView.builder(
                            itemCount: filteredFormulas.length,
                            itemBuilder: (context, index) {
                              final f = filteredFormulas[index];
                              return _buildFormulaTile(
                                f["name"]!,
                                f["formula"]!,
                                category: f["category"]!,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMedalGallery() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> scores = prefs.getStringList('quiz_scores') ?? [];
    int gold = 0, silver = 0, bronze = 0;
    for (var s in scores) {
      try {
        int score = int.parse(s.split("/")[0]);
        if (score >= 14)
          gold++;
        else if (score >= 12)
          silver++;
        else if (score >= 10)
          bronze++;
      } catch (_) {}
    }

    int villageRank = -1; // -1 means loading or offline/unranked
    bool isLoadingRank = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Start fetch once if loading
            if (isLoadingRank) {
              http
                  .get(Uri.parse("$globalServerUrl/leaderboard"))
                  .timeout(const Duration(seconds: 2))
                  .then((response) {
                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);
                      List<dynamic> lb = data["leaderboard"] ?? [];
                      int rank = -1;
                      for (int i = 0; i < lb.length; i++) {
                        if (lb[i]["name"].toString().toLowerCase().trim() ==
                            _userName.toLowerCase().trim()) {
                          rank = i + 1;
                          break;
                        }
                      }
                      if (context.mounted) {
                        setDialogState(() {
                          villageRank = rank;
                          isLoadingRank = false;
                        });
                      }
                    } else {
                      if (context.mounted) {
                        setDialogState(() {
                          isLoadingRank = false;
                        });
                      }
                    }
                  })
                  .catchError((_) {
                    if (context.mounted) {
                      setDialogState(() {
                        isLoadingRank = false;
                      });
                    }
                  });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Medal Gallery 🏆",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "QUIZ EXCELLENCE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMedalRow(
                    "Gold Medal (14+ Score) 🥇",
                    gold,
                    Colors.amber,
                  ),
                  _buildMedalRow(
                    "Silver Medal (12+ Score) 🥈",
                    silver,
                    Colors.blueGrey,
                  ),
                  _buildMedalRow(
                    "Bronze Medal (10+ Score) 🥉",
                    bronze,
                    Colors.brown,
                  ),
                  const Divider(height: 24),
                  const Text(
                    "VILLAGE LEADERBOARD RANK",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingRank)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (villageRank == 1)
                    _buildMedalRow("Village Champion Gold 👑", 1, Colors.amber)
                  else if (villageRank == 2 || villageRank == 3)
                    _buildMedalRow(
                      "Village Elite Silver 🎖️",
                      1,
                      Colors.blueGrey,
                    )
                  else if (villageRank >= 4 && villageRank <= 10)
                    _buildMedalRow(
                      "Village Challenger Bronze 🏅",
                      1,
                      Colors.brown,
                    )
                  else if (scores.isNotEmpty)
                    _buildMedalRow(
                      "Village Contender Medal 🎗️",
                      1,
                      Colors.lightBlueAccent,
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "Take a quiz to get ranked in the village!",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "PROUD!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMedalRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: color),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            "$count",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _showScienceGlossary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Science Glossary 📖",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildGlossaryTile(
                    "Evaporation",
                    "Process of liquid turning into gas.",
                    "वाष्पीकरण",
                  ),
                  _buildGlossaryTile(
                    "Molecule",
                    "Group of atoms bonded together.",
                    "अणु",
                  ),
                  _buildGlossaryTile(
                    "Friction",
                    "Force that opposes motion.",
                    "घर्षण",
                  ),
                  _buildGlossaryTile(
                    "Gravity",
                    "Force pulling objects to center.",
                    "गुरुत्वाकर्षण",
                  ),
                  _buildGlossaryTile(
                    "Photosynthesis",
                    "Plants making food using sunlight.",
                    "प्रकाश संश्लेषण",
                  ),
                  _buildGlossaryTile(
                    "Atom",
                    "Smallest unit of matter.",
                    "परमाणु",
                  ),
                  _buildGlossaryTile("Cell", "Basic unit of life.", "कोशिका"),
                  _buildGlossaryTile(
                    "Ecosystem",
                    "Community of living organisms.",
                    "पारिस्थितिकी तंत्र",
                  ),
                  _buildGlossaryTile("Acid", "Substance with pH < 7.", "अम्ल"),
                  _buildGlossaryTile("Base", "Substance with pH > 7.", "क्षार"),
                  _buildGlossaryTile(
                    "Catalyst",
                    "Substance that speeds up a chemical reaction.",
                    "उत्प्रेरक",
                  ),
                  _buildGlossaryTile(
                    "Reflection",
                    "Bouncing back of light waves from a surface.",
                    "परावर्तन",
                  ),
                  _buildGlossaryTile(
                    "Refraction",
                    "Bending of light as it passes between mediums.",
                    "अपवर्तन",
                  ),
                  _buildGlossaryTile(
                    "Respiration",
                    "Process of releasing energy from food.",
                    "श्वसन",
                  ),
                  _buildGlossaryTile(
                    "Transpiration",
                    "Loss of water vapor from plant leaves.",
                    "वाष्पोत्सर्जन",
                  ),
                  _buildGlossaryTile(
                    "Pollination",
                    "Transfer of pollen from anther to stigma.",
                    "परागण",
                  ),
                  _buildGlossaryTile(
                    "Acceleration",
                    "Rate of change of velocity.",
                    "त्वरण",
                  ),
                  _buildGlossaryTile(
                    "Inertia",
                    "Resistance to change in state of motion.",
                    "जड़त्व",
                  ),
                  _buildGlossaryTile(
                    "Magnetism",
                    "Attraction or repulsion force of magnets.",
                    "चुंबकत्व",
                  ),
                  _buildGlossaryTile(
                    "Temperature",
                    "Degree of hotness or coldness.",
                    "तापमान",
                  ),
                  _buildGlossaryTile(
                    "Cell Wall",
                    "Rigid outer structural layer of plant cells.",
                    "कोशिका भित्ति",
                  ),
                  _buildGlossaryTile(
                    "Tissue",
                    "Group of similar cells performing a function.",
                    "ऊतक",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlossaryTile(String word, String def, String hi) {
    return ListTile(
      title: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(def),
      trailing: Text(
        hi,
        style: const TextStyle(
          color: Colors.indigo,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFormulaTile(
    String name,
    String formula, {
    required String category,
  }) {
    IconData iconData = Icons.calculate_rounded;
    Color iconColor = Colors.blue;
    if (category == "Physics") {
      iconData = Icons.bolt_rounded;
      iconColor = Colors.orange;
    } else if (category == "Chemistry") {
      iconData = Icons.science_rounded;
      iconColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Text(
              formula,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.indigo.shade900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// QUIZ SCREEN
// ==========================================
class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String _subject = "Science";
  String _classLevel = "10";
  String _difficulty = "easy";
  String _language = "en";
  String _topic = "General";
  int _score = 0;
  int _streak = 0;

  bool _isSetupComplete = false;
  int _questionsAsked = 0;
  int _correctInCurrentBatch = 0;
  bool _isQuizFinished = false;
  List<String> _pastScores = [];
  List<String> _askedQuestions = [];

  bool _isLoading = false;
  Map<String, dynamic>? _currentQuestion;
  int? _selectedOptionIndex;
  bool _isAnswerChecked = false;
  String _userName = "Student";
  bool _isVoiceMode = false;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final List<String> _subjects = ["Science", "Math", "English"];
  final List<String> _classes = ["6", "7", "8", "9", "10"];
  final List<String> _languages = ["en", "hi", "mr"];
  List<String> _topics = ["General"];

  @override
  void initState() {
    super.initState();
    _loadPastScores();
    _loadUserName();
    _speech.initialize();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              "$globalServerUrl/topics?lang=$_language&subject=$_subject&class_level=$_classLevel",
            ),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _topics = List<String>.from(data["topics"]);
          if (!_topics.contains(_topic)) {
            _topic = _topics.isNotEmpty ? _topics[0] : "General";
          }
        });
        return;
      }
    } catch (e) {
      print("Server offline, fetching topics locally...");
    }
    _fetchTopicsOffline();
  }

  Future<void> _fetchTopicsOffline() async {
    try {
      final String csvData = await rootBundle.loadString(
        'assets/quiz_database.csv',
      );
      List<String> lines = csvData.split('\n');
      Set<String> localTopics = {"General"};

      for (var line in lines) {
        if (line.trim().isEmpty ||
            line.startsWith('##') ||
            line.startsWith('lang'))
          continue;
        List<String> parts = line.split(',');
        if (parts.length < 11) continue;

        if (parts[0].trim().toLowerCase() == _language.toLowerCase() &&
            parts[1].trim() == _classLevel &&
            parts[2].trim().toLowerCase() == _subject.toLowerCase()) {
          localTopics.add(parts[10].trim());
        }
      }

      setState(() {
        _topics = localTopics.toList()..sort();
        if (!_topics.contains(_topic)) {
          _topic = _topics.isNotEmpty ? _topics[0] : "General";
        }
      });
    } catch (e) {
      print("Offline topics error: $e");
    }
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Student";
    });
  }

  Future<void> _loadPastScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _pastScores = prefs.getStringList('quiz_scores') ?? [];
    });
  }

  void _showScoreHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🏆 Past Scores",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _pastScores.isEmpty
                    ? const Center(
                        child: Text(
                          "No scores yet. Complete a quiz to see your history!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _pastScores.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(
                              Icons.star,
                              color: Colors.orange,
                            ),
                            title: Text(
                              _pastScores[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchNextQuestion() async {
    if (_questionsAsked >= 15) {
      setState(() {
        _isQuizFinished = true;
      });
      _saveScore();
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedOptionIndex = null;
      _isAnswerChecked = false;
      _currentQuestion = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse("$globalServerUrl/quiz"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "lang": _language,
              "subject": _subject,
              "class_level": _classLevel,
              "difficulty": _difficulty,
              "topic": _topic,
              "asked": _askedQuestions,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["error"] != null) {
          await _fetchNextQuestionOffline();
        } else {
          setState(() {
            _currentQuestion = data;
            _askedQuestions.add(data["question"]);
            _isLoading = false;
          });
          if (_isVoiceMode) _startVoiceListening();
          return;
        }
      } else {
        await _fetchNextQuestionOffline();
      }
    } catch (e) {
      await _fetchNextQuestionOffline();
    }
  }

  void _showCertificateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.amber, width: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium,
                size: 100,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              const Text(
                "CERTIFICATE OF MASTERY",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 40),
              const Text(
                "This is to certify that",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "has successfully mastered",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              Text(
                "$_subject - $_topic",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "With a Perfect Score of 15/15",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
              const Divider(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                    style: const TextStyle(fontSize: 10),
                  ),
                  const Text(
                    "GramNet AI Academy",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("PROUDLY DONE"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveScore() async {
    print("Saving score: $_score/$_questionsAsked");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String scoreEntry =
        "$_score/$_questionsAsked on ${DateTime.now().day}/${DateTime.now().month} (${_subject})";

    // 1. Always Save Locally (for Progress Charts)
    List<String> localScores = prefs.getStringList('quiz_scores') ?? [];
    localScores.insert(0, scoreEntry);
    await prefs.setStringList('quiz_scores', localScores);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🏆 Performance Saved Successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Update XP
    int currentXP = prefs.getInt('total_xp') ?? 0;
    await prefs.setInt('total_xp', currentXP + (_score * 10));

    // NEW: Update Daily Streak
    String lastDate = prefs.getString('last_study_date') ?? "";
    String today =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    if (lastDate != today) {
      int currentStreak = prefs.getInt('daily_streak') ?? 0;
      await prefs.setInt('daily_streak', currentStreak + 1);
      await prefs.setString('last_study_date', today);
    }

    globalUpdateTrigger.add(null); // Notify dashboard to refresh stats

    // NEW: Show Certificate on Perfect Score
    if (_score >= 15 && _questionsAsked >= 15) {
      _showCertificateDialog();
    }

    // 2. Try to Sync with Global Leaderboard
    try {
      final response = await http
          .post(
            Uri.parse("$globalServerUrl/submit_score"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": _userName,
              "score": _score,
              "subject": _subject,
              "class_level": _classLevel,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print("Score synced successfully!");
      } else {
        _queueForSync();
      }
    } catch (e) {
      _queueForSync();
    }
  }

  Future<void> _queueForSync() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList('pending_sync_scores') ?? [];
    pending.add(
      jsonEncode({
        "name": _userName,
        "score": _score,
        "subject": _subject,
        "class_level": _classLevel,
        "timestamp": DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList('pending_sync_scores', pending);
    print("Offline: Score queued for future sync.");
  }

  Future<void> _fetchNextQuestionOffline() async {
    if (_questionsAsked >= 15) {
      setState(() {
        _isQuizFinished = true;
      });
      _saveScore();
      return;
    }
    try {
      final String csvData = await rootBundle.loadString(
        'assets/quiz_database.csv',
      );
      List<String> lines = csvData.split('\n');
      List<Map<String, dynamic>> validQuestions = [];

      for (var line in lines) {
        if (line.trim().isEmpty ||
            line.startsWith('##') ||
            line.startsWith('lang'))
          continue;
        List<String> parts = line.split(',');
        if (parts.length < 11) continue;

        if (parts[0].trim().toLowerCase() == _language.toLowerCase() &&
            parts[1].trim() == _classLevel &&
            parts[2].trim().toLowerCase() == _subject.toLowerCase() &&
            parts[9].trim().toLowerCase() == _difficulty.toLowerCase() &&
            parts[10].trim().toLowerCase() == _topic.toLowerCase() &&
            !_askedQuestions.contains(parts[3].trim())) {
          validQuestions.add({
            "question": parts[3].trim(),
            "options": [parts[4], parts[5], parts[6], parts[7]],
            "answer": parts[8],
          });
        }
      }

      if (validQuestions.isEmpty) {
        // Broaden search if no matches found for topic/difficulty
        for (var line in lines) {
          if (line.trim().isEmpty ||
              line.startsWith('##') ||
              line.startsWith('lang'))
            continue;
          List<String> parts = line.split(',');
          if (parts.length < 11) continue;
          if (parts[0].trim().toLowerCase() == _language.toLowerCase() &&
              parts[1].trim() == _classLevel &&
              parts[2].trim().toLowerCase() == _subject.toLowerCase() &&
              !_askedQuestions.contains(parts[3].trim())) {
            validQuestions.add({
              "question": parts[3].trim(),
              "options": [parts[4], parts[5], parts[6], parts[7]],
              "answer": parts[8],
            });
          }
        }
      }

      if (validQuestions.isEmpty) {
        setState(() {
          _isQuizFinished = true;
        });
        _saveScore();
        return;
      }

      if (validQuestions.isNotEmpty) {
        final q = validQuestions[Random().nextInt(validQuestions.length)];
        List<String> options = [
          q["options"][0],
          q["options"][1],
          q["options"][2],
          q["options"][3],
        ];
        int answerIndex = options.indexOf(q["answer"]);
        if (answerIndex == -1) answerIndex = 0;

        setState(() {
          _currentQuestion = {
            "question": q["question"],
            "options": options,
            "answer_index": answerIndex,
          };
          _askedQuestions.add(q["question"]);
        });

        // Auto-start listening if voice mode is on
        if (_isVoiceMode) {
          Future.delayed(
            const Duration(milliseconds: 500),
            _startVoiceListening,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Offline Quiz Error: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startVoiceListening() async {
    if (!_isVoiceMode) return;

    if (_speech.isAvailable) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          String result = val.recognizedWords.toLowerCase();
          if (result.contains("option a") || result.contains("option 1"))
            _checkAnswer(0);
          else if (result.contains("option b") || result.contains("option 2"))
            _checkAnswer(1);
          else if (result.contains("option c") || result.contains("option 3"))
            _checkAnswer(2);
          else if (result.contains("option d") || result.contains("option 4"))
            _checkAnswer(3);

          if (_isAnswerChecked) {
            _speech.stop();
            setState(() => _isListening = false);
          }
        },
      );
    }
  }

  void _checkAnswer(int selectedIndex) {
    if (_isAnswerChecked) return;

    int correctIndex = _currentQuestion!["answer_index"];
    bool isCorrect = (selectedIndex == correctIndex);

    setState(() {
      _selectedOptionIndex = selectedIndex;
      _isAnswerChecked = true;
      _questionsAsked++;

      if (isCorrect) {
        _score++;
        _correctInCurrentBatch++;
        _streak++;

        // Promote difficulty on a consecutive streak of 3
        if (_streak > 0 && _streak % 3 == 0) {
          if (_difficulty == "easy") {
            _difficulty = "medium";
          } else if (_difficulty == "medium") {
            _difficulty = "hard";
          }
        }
      } else {
        // Demote instantly on any incorrect answer
        if (_difficulty == "hard") {
          _difficulty = "medium";
        } else if (_difficulty == "medium") {
          _difficulty = "easy";
        }
        _streak = 0; // Reset streak
        _correctInCurrentBatch = 0;
      }
    });
  }

  Widget _buildResultsDashboard() {
    double percentage = _score / (_questionsAsked > 0 ? _questionsAsked : 1);
    String recommendation = _difficulty;
    if (percentage >= 0.8) {
      if (_difficulty == "easy")
        recommendation = "medium";
      else if (_difficulty == "medium")
        recommendation = "hard";
    } else if (percentage < 0.5) {
      if (_difficulty == "hard")
        recommendation = "medium";
      else if (_difficulty == "medium")
        recommendation = "easy";
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              "Great Job, $_userName!",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              (_score / (_questionsAsked > 0 ? _questionsAsked : 1) >= 0.8)
                  ? "You're a Star! Excellent performance."
                  : (_score / (_questionsAsked > 0 ? _questionsAsked : 1) >= 0.5
                        ? "Good job! Keep practicing to get better."
                        : "Keep trying! You can do it."),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(
              "Final Score: $_score / $_questionsAsked",
              style: const TextStyle(fontSize: 22, color: Colors.indigo),
            ),
            const SizedBox(height: 24),
            Text(
              "Recommended Next Level:",
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: recommendation == 'hard'
                    ? Colors.red.shade100
                    : (recommendation == 'medium'
                          ? Colors.orange.shade100
                          : Colors.green.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recommendation.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: recommendation == 'hard'
                      ? Colors.red.shade800
                      : (recommendation == 'medium'
                            ? Colors.orange.shade800
                            : Colors.green.shade800),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _isSetupComplete = false;
                  _isQuizFinished = false;
                  _questionsAsked = 0;
                  _score = 0;
                  _streak = 0;
                  _correctInCurrentBatch = 0;
                  _currentQuestion = null;
                  _difficulty = recommendation;
                  _askedQuestions.clear();
                });
              },
              child: const Text(
                "Retake Quiz",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isQuizFinished) return _buildResultsDashboard();

    if (!_isSetupComplete) {
      return _buildSetupScreen();
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$_topic Quiz",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Class $_classLevel • $_subject",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _isSetupComplete = false),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F7FB),
        child: Column(
          children: [
            _buildQuizStatsHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A237E),
                      ),
                    )
                  : _currentQuestion == null
                  ? _buildStartCta()
                  : _buildQuestionCard(),
            ),
            if (_isVoiceMode) _buildVoiceIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF303F9F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo.png', height: 50),
                    const SizedBox(width: 16),
                    const Text(
                      "Quiz Master",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  "LEARNING SETUP",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Configure your learning challenge",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                _buildRecentPerformanceCard(), // NEW: Recent performance
                const SizedBox(height: 24),
                _buildSetupCard(
                  "1. Select Subject",
                  _subjects,
                  _subject,
                  (val) => setState(() {
                    _subject = val;
                    _updateTopics();
                  }),
                  Icons.menu_book_rounded,
                ),
                const SizedBox(height: 16),
                _buildSetupCard(
                  "2. Select Class",
                  _classes,
                  _classLevel,
                  (val) => setState(() => _classLevel = val),
                  Icons.school_rounded,
                ),
                const SizedBox(height: 16),
                _buildTopicSetupCard(),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: const Color(0xFF1A237E),
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isSetupComplete = true;
                      _questionsAsked = 0;
                      _score = 0;
                      _streak = 0;
                      _correctInCurrentBatch = 0;
                      _currentQuestion = null;
                      _askedQuestions.clear();
                    });
                  },
                  child: const Text(
                    "START LEARNING",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPerformanceCard() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        List<String> scores = snapshot.data!.getStringList('quiz_scores') ?? [];
        if (scores.isEmpty) return const SizedBox();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    "Recent Results",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...scores.take(3).map((s) {
                try {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.contains(" on ") ? s.split(" on ")[1] : "Session",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          s.split(" on ")[0],
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                } catch (_) {
                  return const SizedBox();
                }
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetupCard(
    String title,
    List<String> options,
    String currentVal,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              bool isSelected = opt == currentVal;
              return GestureDetector(
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.amber
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    opt.toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1A237E)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            "LEVEL",
            _difficulty.toUpperCase(),
            _difficulty == 'hard'
                ? Colors.red
                : (_difficulty == 'medium' ? Colors.orange : Colors.green),
          ),
          _buildStatItem("SCORE", "$_score", Colors.indigo),
          _buildStatItem("STREAK", "🔥 $_streak", Colors.orange),
          _buildStatItem("Q.NO", "$_questionsAsked", Colors.blueGrey),
          // Voice Mode Toggle
          Column(
            children: [
              const Text(
                "VOICE",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _isVoiceMode,
                activeColor: Colors.redAccent,
                onChanged: (val) {
                  setState(() => _isVoiceMode = val);
                  if (val) _startVoiceListening();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStartCta() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.rocket_launch_rounded,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          const Text(
            "Ready to learn?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _fetchNextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
            ),
            child: const Text(
              "START LEARNING",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              _currentQuestion!["question"],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.5,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(4, (index) {
            bool isSelected = _selectedOptionIndex == index;
            bool isCorrect =
                _isAnswerChecked && index == _currentQuestion!["answer_index"];
            bool isWrong =
                _isAnswerChecked &&
                isSelected &&
                index != _currentQuestion!["answer_index"];

            Color cardColor = Colors.white;
            Color borderColor = Colors.grey.shade200;
            if (isCorrect) {
              cardColor = const Color(0xFFE8F5E9);
              borderColor = Colors.green;
            } else if (isWrong) {
              cardColor = const Color(0xFFFFEBEE);
              borderColor = Colors.red;
            } else if (isSelected) {
              cardColor = const Color(0xFFE8EAF6);
              borderColor = const Color(0xFF3F51B5);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => _checkAnswer(index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      if (isSelected && !_isAnswerChecked)
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCorrect
                              ? Colors.green
                              : (isWrong
                                    ? Colors.red
                                    : (isSelected
                                          ? const Color(0xFF3F51B5)
                                          : Colors.grey.shade100)),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: isSelected || _isAnswerChecked
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _currentQuestion!["options"][index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isCorrect
                                ? Colors.green.shade900
                                : (isWrong
                                      ? Colors.red.shade900
                                      : Colors.black87),
                          ),
                        ),
                      ),
                      if (_isAnswerChecked &&
                          index == _currentQuestion!["answer_index"])
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        ),
                      if (_isAnswerChecked &&
                          isSelected &&
                          index != _currentQuestion!["answer_index"])
                        const Icon(Icons.cancel_rounded, color: Colors.red),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_isAnswerChecked) ...[
            const SizedBox(height: 24),
            _buildNextButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _fetchNextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "CONTINUE",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: _isListening
            ? Colors.red.withOpacity(0.1)
            : Colors.indigo.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: _isListening
                ? Colors.red.withOpacity(0.2)
                : Colors.indigo.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : Colors.indigo,
            size: 24,
          ),
          const SizedBox(width: 16),
          Text(
            _isListening ? "I'M LISTENING..." : "VOICE MODE READY",
            style: TextStyle(
              color: _isListening ? Colors.red : Colors.indigo,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSetupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.topic_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Text(
                "3. Choose Your Topic",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _topics.contains(_topic)
                  ? _topic
                  : (_topics.isNotEmpty ? _topics[0] : "General"),
              dropdownColor: const Color(0xFF3949AB),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.amber),
              underline: Container(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: _topics
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _topic = val!),
            ),
          ),
        ],
      ),
    );
  }

  void _updateTopics() {
    _fetchTopics();
  }
}

// ==========================================
// PROFILE SCREEN
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Student";
  int _totalXP = 0;
  int _totalQuestions = 0;
  List<String> _quizScores = [];
  StreamSubscription? _updateSub;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _updateSub = globalUpdateTrigger.stream.listen((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> scores = prefs.getStringList('quiz_scores') ?? [];
    int quizXP = 0;
    for (var s in scores) {
      try {
        quizXP += int.parse(s.split("/")[0]) * 10;
      } catch (_) {}
    }
    int chatXP = prefs.getInt('chat_xp_total') ?? 0;

    setState(() {
      _userName = prefs.getString('user_name') ?? "Student";
      _totalXP = quizXP + chatXP;
      _totalQuestions = prefs.getInt('total_questions') ?? 0;
      _quizScores = scores;
    });
  }

  int get _userLevel => (_totalXP / 100).floor() + 1;
  List<String> get _badges {
    List<String> badges = ["🎓 Novice Learner"];
    if (_userLevel >= 5) badges.add("🥈 Intermediate Scholar");
    if (_userLevel >= 10) badges.add("🥇 Master Polymath");
    if (_quizScores.any((s) => s.startsWith("15/15")))
      badges.add("🎯 Perfectionist");
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
          ),
        ),
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(),
                  const SizedBox(height: 32),
                  const Text(
                    "Study Tools",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildToolCard(
                          "Library",
                          Icons.book,
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LibraryScreen(
                                  classLevel: "10",
                                  subject: "Science",
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildToolCard(
                          "Rank",
                          Icons.emoji_events,
                          Colors.amber,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaderboardScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildToolCard(
                          "Parents",
                          Icons.family_restroom,
                          Colors.orange,
                          _showParentAuth,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildBadgesGrid(),
                  const SizedBox(height: 32),
                  const Text(
                    "Learning Progress",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(),
                  const SizedBox(height: 32),
                  const Text(
                    "Knowledge Map",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildKnowledgeMap(),
                  const SizedBox(height: 32),
                  const Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivityList(),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.amber,
              child: Text(
                _userName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "Elite Scholar",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _buildXPBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPBar() {
    int nextLevelXP = _userLevel * 100;
    double progress = (_totalXP % 100) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Lvl $_userLevel",
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              "${_totalXP % 100} / 100 XP",
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total XP",
                "$_totalXP",
                Icons.bolt_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Quizzes",
                "${_quizScores.length}",
                Icons.assignment_rounded,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Questions Asked",
                "$_totalQuestions",
                Icons.question_answer_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    if (_quizScores.isEmpty) {
      return const Center(
        child: Text(
          "No activities recorded yet.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: _quizScores.take(5).map((s) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.quiz, color: Colors.white, size: 20),
            ),
            title: Text(
              s.split(" (")[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              s.contains("(") ? s.split("(")[1].replaceAll(")", "") : "Quiz",
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKnowledgeMap() {
    List<String> topics = ["Basics", "Medium", "Advanced", "Expert", "Legend"];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(topics.length, (index) {
          bool unlocked = _userLevel > (index * 3);
          return Column(
            children: [
              Icon(
                unlocked
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
                color: unlocked ? Colors.green : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                topics[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Achievements",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _badges
              .map(
                (b) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    b,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showParentAuth() {
    TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Parental Access"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Enter Parent PIN (Default: 1234)",
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == "1234") {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentDashboard(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Wrong PIN!")));
              }
            },
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    List<FlSpot> spots = [];
    int displayCount = _quizScores.length > 7 ? 7 : _quizScores.length;
    List<String> lastScores = _quizScores
        .sublist(0, displayCount)
        .reversed
        .toList();

    for (int i = 0; i < lastScores.length; i++) {
      try {
        String scoreStr = lastScores[i].split("/")[0];
        spots.add(FlSpot(i.toDouble(), double.parse(scoreStr)));
      } catch (e) {}
    }

    return Container(
      height: 225,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: spots.isEmpty
          ? const Center(
              child: Text(
                "Take more quizzes to see progress!",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.indigo.shade800,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Score: ${spot.y.toInt()}/15',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      "Quiz Attempts (Latest 7)",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    axisNameSize: 14,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "T${value.toInt() + 1}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      "Score",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    axisNameSize: 14,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
                    left: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.indigo,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.indigo.withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 15,
              ),
            ),
    );
  }
}

// ==========================================
// OFFLINE LIBRARY SCREEN
// ==========================================
class LibraryScreen extends StatefulWidget {
  final String classLevel;
  final String subject;
  const LibraryScreen({
    Key? key,
    required this.classLevel,
    required this.subject,
  }) : super(key: key);
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Map<String, dynamic> _downloadedBooks = {};
  Map<String, dynamic> _availableBooks = {};
  bool _isLoading = false;
  String? _downloadingBook;
  late String _selectedClass;
  late String _selectedSubject;
  String _selectedLanguage = "en";

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.classLevel;
    _selectedSubject = widget.subject;
    _loadLocalLibrary();
    _fetchAvailableBooks();
  }

  Future<void> _loadLocalLibrary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String manifestStr = prefs.getString('library_manifest') ?? "{}";
    Map<String, dynamic> manifest = jsonDecode(manifestStr);

    // Add Pre-bundled Offline Content if Library is empty
    if (manifest.isEmpty) {
      manifest = {
        "Essential Science Facts (Offline)": [
          "1. Light travels at approximately 300,000 kilometers per second.",
          "2. The Earth's atmosphere is composed primarily of Nitrogen (78%) and Oxygen (21%).",
          "3. DNA is the molecule that carries genetic information for the development and functioning of an organism.",
        ],
        "Math Quick Reference (Offline)": [
          "1. The sum of angles in a triangle is always 180 degrees.",
          "2. Pythagorean Theorem: a² + b² = c² for a right-angled triangle.",
          "3. Area of a circle = πr²",
        ],
        "English Grammar Mastery (Offline)": [
          "1. Active Voice: The subject performs the action. (e.g., 'The cat chased the mouse.')",
          "2. Passive Voice: The subject is acted upon. (e.g., 'The mouse was chased by the cat.')",
          "3. Conjunctions are words that connect sentences or clauses. (e.g., and, but, or, because).",
        ],
      };
      await prefs.setString('library_manifest', jsonEncode(manifest));
    }

    setState(() {
      _downloadedBooks = manifest;
    });
  }

  Future<void> _fetchAvailableBooks() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse("$globalServerUrl/download_library"))
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        setState(() {
          _availableBooks = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Error fetching books: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadBook(String title) async {
    setState(() => _downloadingBook = title);
    try {
      final response = await http
          .get(
            Uri.parse(
              "$globalServerUrl/download_book?title=${Uri.encodeComponent(title)}&lang=$_selectedLanguage",
            ),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["error"] != null) {
          throw Exception(data["error"]);
        }

        List<String> bookChunks = List<String>.from(data["chunks"]);
        SharedPreferences prefs = await SharedPreferences.getInstance();

        String manifestStr = prefs.getString('library_manifest') ?? "{}";
        Map<String, dynamic> manifest = jsonDecode(manifestStr);
        String savedTitle = "$title (${_selectedLanguage.toUpperCase()})";
        manifest[savedTitle] = bookChunks;

        await prefs.setString('library_manifest', jsonEncode(manifest));

        setState(() {
          _downloadedBooks = manifest;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ $savedTitle Added to Library!")),
        );
      } else {
        throw Exception("Server returned status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download Error: $e")));
    } finally {
      setState(() => _downloadingBook = null);
    }
  }

  void _viewBookContent(String title) {
    List<String> chunks = List<String>.from(_downloadedBooks[title]);
    String fullContent = chunks.join("\n");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: SelectionArea(
                  child: Text(
                    fullContent,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearLibrary() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('library_manifest');
    setState(() {
      _downloadedBooks = {};
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("🗑️ Library Cleared!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NCERT Offline Library"),
        backgroundColor: Colors.blue,
        actions: [
          if (_downloadedBooks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearLibrary,
              tooltip: "Clear All",
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Card for dynamic Class, Subject, and Language Selection
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Class Selector Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CLASS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClass,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ["6", "7", "8", "9", "10"]
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    "Class $c",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClass = val!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Subject Selector Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SUBJECT",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSubject,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ["Science", "Math", "English"]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSubject = val!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Language Selector Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "LANGUAGE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "en",
                              child: Text(
                                "English",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "hi",
                              child: Text(
                                "Hindi",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem(
                              value: "mr",
                              child: Text(
                                "Marathi",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedLanguage = val!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_availableBooks.isNotEmpty)
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text(
                    "⭐ Recommended for You",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._availableBooks.keys
                      .where(
                        (k) =>
                            k.contains("Class $_selectedClass") &&
                            k.contains(_selectedSubject),
                      )
                      .map((title) => _buildBookTile(title)),

                  const Divider(height: 32),
                  const Text(
                    "📚 All NCERT Books",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._availableBooks.keys
                      .where(
                        (k) =>
                            !(k.contains("Class $_selectedClass") &&
                                k.contains(_selectedSubject)),
                      )
                      .map((title) => _buildBookTile(title)),
                ],
              ),
            )
          else if (_isLoading)
            const Expanded(
              flex: 2,
              child: Center(child: CircularProgressIndicator()),
            ),

          const Divider(thickness: 2),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              "📂 Your Downloaded Books",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _downloadedBooks.isEmpty
                ? const Center(
                    child: Text(
                      "No books downloaded yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _downloadedBooks.length,
                    itemBuilder: (context, index) {
                      String title = _downloadedBooks.keys.elementAt(index);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.library_books,
                            color: Colors.green,
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${_downloadedBooks[title].length} Paragraphs/Lines Available",
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                          ),
                          onTap: () => _viewBookContent(title),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                const Text(
                  "Need the full official PDF?",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final Uri url = Uri.parse(
                      'https://ncert.nic.in/textbook.php',
                    );
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Could not open NCERT website."),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text(
                    "Open Official NCERT Download Portal",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookTile(String title) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.book, color: Colors.blue),
        title: Text(title),
        trailing: _downloadingBook == title
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: () => _downloadBook(title),
              ),
      ),
    );
  }
}

// ==========================================
// VILLAGE LEADERBOARD SCREEN
// ==========================================
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _topStudents = [];
  bool _isLoading = true;
  String _selectedSubject = "All";
  String _selectedClass = "All";

  final List<String> _subjects = ["All", "Science", "Math", "English"];
  final List<String> _classes = ["All", "6", "7", "8", "9", "10"];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      String url = "$globalServerUrl/leaderboard?";
      if (_selectedSubject != "All") url += "subject=$_selectedSubject&";
      if (_selectedClass != "All") url += "class_level=$_selectedClass&";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        setState(() {
          _topStudents = jsonDecode(response.body)["leaderboard"];
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print("Leaderboard offline: $e");
    }

    if (mounted) {
      setState(() {
        _topStudents = []; // Clear current list if request failed
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Village Top Performers",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.amber.shade800,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              globalIsManualOffline
                  ? Icons.cloud_off_rounded
                  : (globalIsOffline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded),
              color: globalIsManualOffline
                  ? Colors.white54
                  : (globalIsOffline ? Colors.white70 : Colors.greenAccent),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade800,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Village Pride",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Top performers in your community",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Subject Filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedSubject,
                              items: _subjects
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedSubject = val!);
                                _fetchLeaderboard();
                              },
                              underline: Container(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Class Filter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedClass,
                              items: _classes
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c == "All" ? "All Classes" : "Class $c",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _selectedClass = val!);
                                _fetchLeaderboard();
                              },
                              underline: Container(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _topStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                globalIsOffline
                                    ? Icons.wifi_off_rounded
                                    : Icons.info_outline_rounded,
                                size: 64,
                                color: Colors.amber.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                globalIsOffline
                                    ? "Leaderboard is Offline"
                                    : "No Data Found",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 8,
                                ),
                                child: Text(
                                  globalIsOffline
                                      ? "Connect to the internet to see how you rank against other students in the village!"
                                      : "No one has taken a quiz in this category yet. Be the first to lead the community!",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _topStudents.length,
                          itemBuilder: (context, index) {
                            final student = _topStudents[index];
                            final isTop3 = index < 3;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isTop3
                                      ? Colors.amber
                                      : Colors.grey[200],
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      color: isTop3
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student["name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Subject: ${student["subject"]} • Class: ${student["class_level"] ?? '10'}",
                                ),
                                trailing: Text(
                                  "${student["score"]}/15",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[800],
                                  ),
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

// ==========================================
// PARENT DASHBOARD SCREEN
// ==========================================
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _totalQuestions = 0;
  List<String> _quizScores = [];
  String _studentName = "";

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalQuestions = prefs.getInt('total_questions') ?? 0;
      _quizScores = prefs.getStringList('quiz_scores') ?? [];
      _studentName = prefs.getString('user_name') ?? "Student";
    });
  }

  double get _avgScore {
    if (_quizScores.isEmpty) return 0;
    double totalEarned = 0;
    double totalPossible = 0;
    for (var s in _quizScores) {
      try {
        // Format is "7/15 on Date (Subject)"
        var parts = s.split(" ")[0].split("/");
        totalEarned += double.tryParse(parts[0]) ?? 0;
        totalPossible += double.tryParse(parts[1]) ?? 15;
      } catch (e) {
        totalPossible += 15;
      }
    }
    return totalPossible > 0 ? (totalEarned / totalPossible) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
            ),
          ),
        ),
        title: const Text(
          "Parental Insights",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Report for $_studentName",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Comprehensive study analysis",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatTile(
                    "Total Questions",
                    "$_totalQuestions",
                    Icons.question_answer_rounded,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildStatTile(
                    "Success Rate",
                    "${(_avgScore * 100).toStringAsFixed(1)}%",
                    Icons.trending_up_rounded,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatTile(
                    "Quizzes Done",
                    "${_quizScores.length}",
                    Icons.assignment_turned_in_rounded,
                    Colors.purple,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Teacher's Feedback",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_rounded,
                          color: Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _quizScores.isEmpty
                                ? "Welcome! $_studentName hasn't started any lessons yet. Encourage them to take their first quiz to see performance insights here!"
                                : (_avgScore > 0.7
                                      ? "$_studentName is demonstrating high conceptual clarity. We recommend advancing to 'Hard' level topics to maintain the challenge."
                                      : "$_studentName is making steady progress. Focused practice on 'Medium' topics will help solidify their foundation."),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// BILINGUAL MESSAGE BUBBLE WIDGET
// ==========================================
class BilingualMessageBubble extends StatefulWidget {
  final String topic;
  final String enText;
  final String hiText;
  final Function(String text, String lang) onSpeak;
  final bool isPlaying;
  final String currentlyPlayingText;

  const BilingualMessageBubble({
    Key? key,
    required this.topic,
    required this.enText,
    required this.hiText,
    required this.onSpeak,
    required this.isPlaying,
    required this.currentlyPlayingText,
  }) : super(key: key);

  @override
  State<BilingualMessageBubble> createState() => _BilingualMessageBubbleState();
}

class _BilingualMessageBubbleState extends State<BilingualMessageBubble> {
  String _activeTab = "both"; // Options: "en", "hi", "both"

  @override
  Widget build(BuildContext context) {
    bool isEnPlaying =
        widget.isPlaying && widget.currentlyPlayingText == widget.enText;
    bool isHiPlaying =
        widget.isPlaying && widget.currentlyPlayingText == widget.hiText;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.indigo.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    color: Colors.indigo,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.topic,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "OFFLINE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabButton("both", "English & हिंदी"),
                    _buildTabButton("en", "English"),
                    _buildTabButton("hi", "हिंदी"),
                  ],
                ),
              ),
            ),

            // Content Panel
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeTab == "en" || _activeTab == "both") ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🇬🇧 ", style: TextStyle(fontSize: 18)),
                        Expanded(
                          child: Text(
                            widget.enText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.45,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isEnPlaying ? Icons.stop_circle : Icons.volume_up,
                            color: Colors.indigo,
                            size: 20,
                          ),
                          onPressed: () => widget.onSpeak(widget.enText, "en"),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                  if (_activeTab == "both") ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: Colors.black12,
                        thickness: 0.8,
                      ),
                    ),
                  ],
                  if (_activeTab == "hi" || _activeTab == "both") ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🇮🇳 ", style: TextStyle(fontSize: 18)),
                        Expanded(
                          child: Text(
                            widget.hiText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.45,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isHiPlaying ? Icons.stop_circle : Icons.volume_up,
                            color: Colors.indigo,
                            size: 20,
                          ),
                          onPressed: () => widget.onSpeak(widget.hiText, "hi"),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String id, String label) {
    bool isSelected = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.indigo : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
