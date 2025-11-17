// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MovieNotesApp());
}

class MovieNotesApp extends StatefulWidget {
  const MovieNotesApp({super.key});
  @override
  State<MovieNotesApp> createState() => _MovieNotesAppState();
}

class _MovieNotesAppState extends State<MovieNotesApp> {
  final _authService = AuthService();
  final _navigatorKey = GlobalKey<NavigatorState>();

  ThemeMode _themeMode = ThemeMode.dark;
  bool _pushEnabled = true;
  bool _authorized = false;
  String _nickname = 'Гость';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (_authService.isLoggedIn) {
      final nick = await _authService.getUserNickname() ?? 'Гость';
      setState(() {
        _authorized = true;
        _nickname = nick;
      });
      _initPush();
    }
  }

  Future<void> _initPush() async {
    if (!kIsWeb) {
      await PushService().init();
      PushService().subscribeToNewMovies();
    }
  }

  void _toggleTheme() => setState(() =>
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void _togglePush(bool v) => setState(() => _pushEnabled = v);

  void _onAuthorized(String nickname) async {
    setState(() {
      _authorized = true;
      _nickname = nickname;
    });
    await _initPush(); // ← токен в Firestore
  }

  void _logout() async {
    await _authService.logout();
    setState(() {
      _authorized = false;
      _nickname = 'Гость';
    });
    _navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Заметки о фильмах',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.redAccent,
            elevation: 0),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.redAccent, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.redAccent,
            elevation: 0),
      ),
      initialRoute: _authorized ? '/home' : '/auth',
      routes: {
        '/auth': (_) => AuthScreen(onAuthorized: _onAuthorized),
        '/home': (_) => HomeScreen(
              themeMode: _themeMode,
              pushEnabled: _pushEnabled,
              onPushToggle: _togglePush,
              onThemeToggle: _toggleTheme,
              nickname: _nickname,
              onLogout: _logout,
            ),
        '/verify': (_) => VerifyEmailScreen(
              nickname: _nickname,
              onVerified: () => _onAuthorized(_nickname),
            ),
      },
    );
  }
}