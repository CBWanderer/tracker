// import 'package:location/location.dart';

import 'dart:convert';

import 'package:intl/intl.dart';

class Trip {
  late String id;
  DateTime initialTime;
  DateTime? endTime;
  Position? initialLocation;

  Trip(this.initialTime, {this.endTime, this.initialLocation}) {
    id = initialTime.millisecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "initialTime": initialTime.millisecondsSinceEpoch,
        "endTime": endTime?.millisecondsSinceEpoch,
        "initialLocation": initialLocation?.toString(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory Trip.fromJsonString(String json) => Trip.fromJson(jsonDecode(json));

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        DateTime.fromMillisecondsSinceEpoch(
          json["initialTime"] ?? DateTime.now(),
        ),
        endTime: json["endTime"] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(json["endTime"]),
        initialLocation: json["initialLocation"] == null
            ? null
            : Position.fromJson(
                json["initialLocation"],
              ),
      );

  @override
  String toString() {
    var ret = DateFormat('yyyy-MM-dd hh:mm').format(initialTime);
    if (endTime != null) {
      ret += " ${DateFormat('yyyy-MM-dd hh:mm').format(endTime!)}";
    }
    return ret;
  }
}

class Position {
  double lat = 0.0;
  double lon = 0.0;
  double spd = 0.0;
  late DateTime time;

  Position(this.lat, this.lon, this.spd, {DateTime? time}) {
    this.time = time ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        "lat": lat,
        "lon": lon,
        "spd": spd,
        'time': time.millisecondsSinceEpoch,
      };

  String toJsonString() => jsonEncode(toJson());

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        json["lat"] ?? 0.0,
        json["lon"] ?? 0.0,
        json["spd"] ?? 0.0,
        time: json['time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['time'])
            : null,
      );

  factory Position.fromJsonString(String json) =>
      Position.fromJson(jsonDecode(json));
}
