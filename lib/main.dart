import 'package:background_app/background_location.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//import 'background_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await initializeBackgroundService();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('key', 'Hello World!');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: MaterialApp(
        home: Scaffold(
          body: BackgroundLocation(),
        ),
      ),
    );
  }
}
