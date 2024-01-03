import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location/location.dart';
import 'package:tracker/trips.dart';

class Locator {
  Location location = Location();
  late bool _serviceEnabled;
  bool _tracking = false;
  Timer? _locTimer;
  StreamSubscription<LocationData>? _subscription;
  late PermissionStatus _permissionGranted;
  late LocationData _tempLocation;
  ValueNotifier<LocationData> currentLocation =
      ValueNotifier(LocationData.fromMap({}));
  bool _ready = false;
  String trackBox = "";

  Future<int> initGPS() async {
    _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return -1;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return -2;
      }
    }

    bool enabled = await location.enableBackgroundMode(enable: true);

    print("Background: $enabled");

    _tempLocation = await location.getLocation();
    currentLocation = ValueNotifier(_tempLocation);

    _ready = true;
    return 0;
  }

  void startTracking(String trackId) async {
    if (_tracking) return;

    if (!_ready) await initGPS();

    trackBox = trackId;
    Box box = await Hive.openBox(trackBox);

    _subscription = location.onLocationChanged.listen((loc) {
      _tempLocation = loc;
    });

    _locTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      currentLocation = ValueNotifier(_tempLocation);
      box.add(
        Position(_tempLocation.latitude ?? 0, _tempLocation.longitude ?? 0,
                _tempLocation.speed ?? 0)
            .toJsonString(),
      );
    });

    _tracking = true;
  }

  void stopTracking() async {
    if (_tracking) {
      Hive.box(trackBox).close();
      _subscription!.cancel();
      _locTimer!.cancel();
    }
  }
}
