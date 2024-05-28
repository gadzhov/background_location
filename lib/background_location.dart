import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:carp_background_location/carp_background_location.dart';
import 'package:http/http.dart' as http;

class BackgroundLocation extends StatefulWidget {
  const BackgroundLocation({super.key});

  @override
  BackgroundLocationState createState() => BackgroundLocationState();
}

enum LocationStatus {
  unknown,
  initialized,
  running,
  stopped,
}

class BackgroundLocationState extends State<BackgroundLocation> {
  String logStr = '';
  LocationDto? _lastLocation;
  StreamSubscription<LocationDto>? locationSubscription;
  LocationStatus _status = LocationStatus.unknown;

  @override
  void initState() {
    super.initState();

    LocationManager().interval = 15;
    LocationManager().distanceFilter = 0;
    LocationManager().notificationTitle = 'CARP Location Example';
    LocationManager().notificationMsg = 'CARP is tracking your location';

    _status = LocationStatus.initialized;
  }

  void getCurrentLocation() async => onData(await LocationManager().getCurrentLocation());

  Future<void> onData(LocationDto location) async {
    print('>> $location');
    setState(() {
      _lastLocation = location;
    });

    await http.post(
      Uri.parse('https://4fb4-185-183-34-46.ngrok-free.app/dart-layer/mobile-background-service'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode(location.toJson()),
    );
  }

  /// Is "location always" permission granted?
  Future<bool> isLocationAlwaysGranted() async => await Permission.locationAlways.isGranted;

  /// Tries to ask for "location always" permissions from the user.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> askForLocationAlwaysPermission() async {
    bool granted = await Permission.locationAlways.isGranted;

    if (!granted) {
      if (await Permission.locationWhenInUse.request().isGranted) {
        granted = await Permission.locationAlways.request() == PermissionStatus.granted;
      }
    }

    return granted;
  }

  /// Start listening to location events.
  void start() async {
    // ask for location permissions, if not already granted
    if (!await isLocationAlwaysGranted()) await askForLocationAlwaysPermission();

    locationSubscription?.cancel();
    locationSubscription = LocationManager().locationStream.listen(onData);
    await LocationManager().start();
    setState(() {
      _status = LocationStatus.running;
    });
  }

  void stop() {
    locationSubscription?.cancel();
    LocationManager().stop();
    setState(() {
      _status = LocationStatus.stopped;
    });
  }

  Widget stopButton() => SizedBox(
        width: double.maxFinite,
        child: ElevatedButton(
          onPressed: stop,
          child: const Text('STOP'),
        ),
      );

  Widget startButton() => SizedBox(
        width: double.maxFinite,
        child: ElevatedButton(
          onPressed: start,
          child: const Text('START'),
        ),
      );

  Widget statusText() => Text("Status: ${_status.toString().split('.').last}");

  Widget currentLocationButton() => SizedBox(
        width: double.maxFinite,
        child: ElevatedButton(
          onPressed: getCurrentLocation,
          child: const Text('CURRENT LOCATION'),
        ),
      );

  Widget locationWidget() {
    if (_lastLocation == null) {
      return const Text("No location yet");
    } else {
      return Column(
        children: <Widget>[
          Text(
            '${_lastLocation!.latitude}, ${_lastLocation!.longitude}',
          ),
          const Text(
            '@',
          ),
          Text('${DateTime.fromMillisecondsSinceEpoch(_lastLocation!.time ~/ 1)}')
        ],
      );
    }
  }

  @override
  void dispose() => super.dispose();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('CARP Background Location'),
        ),
        body: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                startButton(),
                stopButton(),
                currentLocationButton(),
                const Divider(),
                statusText(),
                const Divider(),
                locationWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
