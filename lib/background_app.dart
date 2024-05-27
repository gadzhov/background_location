import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundApp extends StatefulWidget {
  const BackgroundApp({super.key});

  @override
  State<BackgroundApp> createState() => _BackgroundAppState();
}

class _BackgroundAppState extends State<BackgroundApp> {
  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationServiceEnabled) {
      print('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    if (await FlutterBackgroundService().startService()) {
      print('FlutterBackgroundService started');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Flutter background service + geolocator'),
    );
  }
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final Position position = await Geolocator.getCurrentPosition();
  await http.post(
    Uri.parse('https://c1d0-94-156-194-28.ngrok-free.app/dart-layer/mobile-background-service'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: json.encode(<String, Object?>{
      'source': 'onIosBackground',
      ...position.toJson(),
    }),
  );

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  //DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'My App Service',
      content: "Updated at ${DateTime.now()}",
    );
  }

  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: 'My App Service',
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('key');
    print('Value: $value');
    final Position position = await Geolocator.getCurrentPosition();
    await http.post(
      Uri.parse('https://c1d0-94-156-194-28.ngrok-free.app/dart-layer/mobile-background-service'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(<String, Object?>{
        'source': 'onStart',
        ...position.toJson(),
      }),
    );
  });
}
