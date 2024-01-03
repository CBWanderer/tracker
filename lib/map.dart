import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tracker/trips.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Title'),
      ),
      body: MapWidget(
        id: id ?? "",
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  const MapWidget({super.key, this.id = ""});

  final String id;

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  void _loadPoints() async {
    print(widget.id);
    if (widget.id != "") {
      Box pointsBox = await Hive.openBox(widget.id);
      setState(() {
        points =
            pointsBox.values.map((e) => Position.fromJsonString(e)).toList();
      });
    }
  }

  List<Position> points = [];

  @override
  void initState() {
    super.initState();
    if (widget.id != "") {
      _loadPoints();
    }
  }

  LatLngBounds boundsFromLatLngList(List<Position> list) {
    double x0 = double.infinity,
        x1 = -double.infinity,
        y0 = double.infinity,
        y1 = -double.infinity;
    for (Position latLng in list) {
      if (latLng.lat > x1) x1 = latLng.lat;
      if (latLng.lat < x0) x0 = latLng.lat;
      if (latLng.lon > y1) y1 = latLng.lon;
      if (latLng.lon < y0) y0 = latLng.lon;
    }
    return LatLngBounds(
        northeast: LatLng(x1 + 0.2, y1), southwest: LatLng(x0 - 0.2, y0));
  }

  @override
  Widget build(BuildContext context) {
    int count = 0;
    Set<Marker> markers = {};
    markers = points
        .map(
          (e) => Marker(
              markerId: MarkerId((count++).toString()),
              position: LatLng(e.lat, e.lon)),
        )
        .toSet();

    return GoogleMap(
      mapType: MapType.hybrid,
      markers: markers,
      initialCameraPosition: markers.isEmpty
          ? _kGooglePlex
          : CameraPosition(
              target: markers.first.position,
              zoom: 10,
            ),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        Future.delayed(
          const Duration(milliseconds: 200),
          () => controller.animateCamera(
            CameraUpdate.newLatLngBounds(
              boundsFromLatLngList(points),
              1,
            ),
          ),
        );
      },
    );
  }

  Future<void> _goToTheLake() async {
    // final GoogleMapController controller = await _controller.future;
    // await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
