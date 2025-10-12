import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:demo_app/start_screen.dart';
import 'package:demo_app/login_screen.dart';
import 'package:demo_app/register_screen.dart';
import 'package:demo_app/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for web or mobile
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDfuVgXEnxmCZQd3Ys_gtNc7_62ew0URnw",
        authDomain: "chatpt-9513d.firebaseapp.com",
        projectId: "chatpt-9513d",
        storageBucket: "chatpt-9513d.appspot.com",
        messagingSenderId: "116957340443",
        appId: "1:116957340443:web:73b1eddef26bf5196969be",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const ChatPTApp());
}

// Theme Notifier for global theme management
class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  Color get primaryColor =>
      _isDarkTheme ? const Color(0xffff9f9f) : const Color(0xff4e80ff);
  Color get secondaryColor =>
      _isDarkTheme ? const Color.fromARGB(50, 255, 130, 130) : const Color.fromARGB(50, 130, 151, 255);
  Color get tertiaryColor => _isDarkTheme ? const Color(0xffaa1b1b) : const Color(0xff1b44aa);
  Color get backgroundColor => _isDarkTheme ? const Color(0xFFF5F6FA) : const Color(0xFFF5F6FA);
  Color get cardColor => Colors.white;
  Color get textColor => Colors.black87;
  Color get subtextColor => Colors.grey.shade600;
}

class ChatPTApp extends StatefulWidget {
  const ChatPTApp({super.key});

  @override
  State<ChatPTApp> createState() => _ChatPTAppState();
}

class _ChatPTAppState extends State<ChatPTApp> {
  final ThemeProvider themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'ChatPT',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'SF Pro Display',
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => StartScreen(themeProvider: themeProvider),
            '/login': (context) => LoginScreen(themeProvider: themeProvider),
            '/register': (context) => RegisterScreen(themeProvider: themeProvider),
            '/main': (context) => MainScreen(themeProvider: themeProvider),
          },
        );
      },
    );
  }
}
