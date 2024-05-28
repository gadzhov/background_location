// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart' as ph;
// import 'package:shared_preferences/shared_preferences.dart';

// class BackgroundApp extends StatefulWidget {
//   const BackgroundApp({super.key});

//   @override
//   State<BackgroundApp> createState() => _BackgroundAppState();
// }

// class _BackgroundAppState extends State<BackgroundApp> {
//   bool _hasPermission = false;
//   String _errorMsg = '';

//   @override
//   void initState() {
//     super.initState();
//     unawaited(_init());
//   }

//   Future<void> _init() async {
//     try {
//       final ph.ServiceStatus locationServiceStatus = await ph.Permission.location.serviceStatus;
//       if (locationServiceStatus == ph.ServiceStatus.disabled) {
//         throw Exception( 'Location services are disabled.');
//       }

//       ph.PermissionStatus permission = await ph.Permission.locationAlways.status;
//       if (permission == ph.PermissionStatus.denied) {
//         permission = await ph.Permission.locationWhenInUse.request();
//         permission = await ph.Permission.locationAlways.request();
//         if (permission == ph.PermissionStatus.denied) {
//           throw Exception('Location permissions are denied');
//         }
//       }

//       if (permission == ph.PermissionStatus.permanentlyDenied) {
//         throw Exception('Location permissions are permanently denied, we cannot request permissions.');
//       }

//       if (await FlutterBackgroundService().startService()) {
//         print('FlutterBackgroundService started');
//         setState(() {
//           _hasPermission = true;
//         });
//       }
//     } catch (error) {
//       setState(() {
//         _hasPermission = false;
//         _errorMsg = error.toString();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const Center(
//           child: Text('Flutter background service + geolocator'),
//         ),
//         if (!_hasPermission) Text(_errorMsg)
//       ],
//     );
//   }
// }

// Future<void> initializeBackgroundService() async {
//   final service = FlutterBackgroundService();

//   service.configure(
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       initialNotificationTitle: 'AWESOME SERVICE',
//       initialNotificationContent: 'Initializing',
//       foregroundServiceNotificationId: 888,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();

//   final Position position = await Geolocator.getCurrentPosition();
//   await http.post(
//     Uri.parse('https://4fb4-185-183-34-46.ngrok-free.app/dart-layer/mobile-background-service'),
//     headers: <String, String>{
//       'Content-Type': 'application/json',
//     },
//     body: json.encode(<String, Object?>{
//       'source': 'onIosBackground',
//       ...position.toJson(),
//     }),
//   );

//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   final prefs = await SharedPreferences.getInstance();
//   DartPluginRegistrant.ensureInitialized();

//   service.on('destroy').listen((event) async {
//     await service.stopSelf();
//   });

//   if (service is AndroidServiceInstance) {
//     service.setForegroundNotificationInfo(
//       title: 'My App Service',
//       content: "Updated at ${DateTime.now()}",
//     );
//   }

//   //Future.delayed(const Duration(seconds: 10), () async => await service.stopSelf());

//   Timer.periodic(const Duration(seconds: 15), (timer) async {
//     if (service is AndroidServiceInstance) {
//       if (await service.isForegroundService()) {
//         // if you don't using custom notification, uncomment this
//         service.setForegroundNotificationInfo(
//           title: 'My App Service',
//           content: "Updated at ${DateTime.now()}",
//         );
//       }
//     }

//     await prefs.reload();
//     final value = prefs.getString('key');
//     print('Value: $value');
//     final Position position = await Geolocator.getCurrentPosition();
//     await http.post(
//       Uri.parse('https://4fb4-185-183-34-46.ngrok-free.app/dart-layer/mobile-background-service'),
//       headers: <String, String>{
//         'Content-Type': 'application/json',
//       },
//       body: json.encode(<String, Object?>{
//         'source': 'onStart',
//         ...position.toJson(),
//       }),
//     );
//   });
// }
