import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tracker/trips.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.id});

  final String? id;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
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

  String _getDirection(double val, [bool isLongitude = false]) {
    if (!isLongitude) {
      return val < 0 ? 'S' : 'N';
    } else {
      return val < 0 ? 'W' : 'E';
    }
  }

  String latitudeToHumanReadableString(double latitude) {
    String direction = _getDirection(latitude);
    latitude = latitude.abs();
    int degrees = latitude.truncate();
    latitude = (latitude - degrees) * 60;
    int minutes = latitude.truncate();
    int seconds = ((latitude - minutes) * 60).truncate();
    return '$direction $degrees°$minutes\'$seconds"';
  }

  String longitudeToHumanReadableString(double longitude) {
    String direction = _getDirection(longitude, true);
    longitude = longitude.abs();
    int degrees = longitude.truncate();
    longitude = (longitude - degrees) * 60;
    int minutes = longitude.truncate();
    int seconds = ((longitude - minutes) * 60).truncate();
    return '$direction $degrees°$minutes\'$seconds"';
  }

  List<Position> points = [];
  void _loadPoints() async {
    if (widget.id != null) {
      Box pointsBox = await Hive.openBox(widget.id!);
      setState(() {
        points =
            pointsBox.values.map((e) => Position.fromJsonString(e)).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    if (widget.id != "") {
      _loadPoints();
    }
    _tabs.addListener(() {
      selected = null;
    });
  }

  late TabController _tabs;
  Position? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Viaje'),
        bottom: TabBar(controller: _tabs, tabs: const [
          Tab(icon: Icon(Icons.table_chart)),
          Tab(icon: Icon(Icons.map)),
        ]),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Scrollbar(
            interactive: true,
            child: ListView.builder(
                itemCount: points.length,
                itemBuilder: (context, i) {
                  var point = points[i];
                  return Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(DateFormat("kk:mm").format(point.time)),
                        Text(
                            "${latitudeToHumanReadableString(point.lat)} ${longitudeToHumanReadableString(point.lon)}"),
                        Text("${point.spd * 3.6} km/h"),
                        IconButton(
                          icon: const Icon(
                            Icons.pin_drop_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              selected = point;
                              print("seleccionando:");
                              print(selected);
                              _tabs.animateTo(1);
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider()
                  ]);
                }),
          ),
          MapWidget(
            // id: widget.id ?? "",
            selected: selected,
            points: points,
          ),
        ],
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  MapWidget({super.key, required this.points, this.selected}) {
    print("Class");
    print(selected);
  }

  // final String id;
  final Position? selected;
  final List<Position> points;

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
  void initState() {
    // TODO: implement initState
    super.initState();
    print("Estdo iniciado");
    print(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    int count = 0;
    if (widget.selected != null) {
      print("Hay seleccion");
    } else {
      print("No hay seleccion");
    }
    Set<Marker> markers = {};

    if (widget.selected != null) {
      markers = {
        Marker(
          markerId: const MarkerId("1"),
          position: LatLng(widget.selected!.lat, widget.selected!.lon),
        )
      };
    } else {
      markers = widget.points
          .map(
            (e) => Marker(
                markerId: MarkerId((count++).toString()),
                position: LatLng(e.lat, e.lon)),
          )
          .toSet();
    }

    print(markers);

    return GoogleMap(
      mapType: MapType.normal,
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
              boundsFromLatLngList(widget.points),
              1,
            ),
          ),
        );
      },
    );
  }
}

class PointList extends StatefulWidget {
  const PointList({super.key, required this.points});

  final List<Position> points;

  @override
  State<PointList> createState() => _PointListState();
}

class _PointListState extends State<PointList> {
  String _getDirection(double val, [bool isLongitude = false]) {
    if (!isLongitude) {
      return val < 0 ? 'S' : 'N';
    } else {
      return val < 0 ? 'W' : 'E';
    }
  }

  String latitudeToHumanReadableString(double latitude) {
    String direction = _getDirection(latitude);
    latitude = latitude.abs();
    int degrees = latitude.truncate();
    latitude = (latitude - degrees) * 60;
    int minutes = latitude.truncate();
    int seconds = ((latitude - minutes) * 60).truncate();
    return '$direction $degrees°$minutes\'$seconds"';
  }

  String longitudeToHumanReadableString(double longitude) {
    String direction = _getDirection(longitude, true);
    longitude = longitude.abs();
    int degrees = longitude.truncate();
    longitude = (longitude - degrees) * 60;
    int minutes = longitude.truncate();
    int seconds = ((longitude - minutes) * 60).truncate();
    return '$direction $degrees°$minutes\'$seconds"';
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      interactive: true,
      child: ListView.builder(
          itemCount: widget.points.length,
          itemBuilder: (context, i) {
            var point = widget.points[i];
            return Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(DateFormat("kk:mm").format(point.time)),
                  Text(
                      "${latitudeToHumanReadableString(point.lat)} ${longitudeToHumanReadableString(point.lon)}"),
                  Text("${point.spd * 3.6} km/h"),
                  IconButton(
                    icon: const Icon(
                      Icons.pin_drop_rounded,
                      color: Colors.red,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const Divider()
            ]);

            const ListTile(
              title: Text("Data"),
            );
          }),
    );
  }
}
