import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tracker/location.dart';
import 'package:tracker/map.dart';
import 'package:tracker/trips.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox("trips");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Viajes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Registro de Viajes'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Box trips = Hive.box("trips");

  bool tracking = false;

  int trackingPos = -1;

  String dateToString(DateTime date) {
    String ret = "${date.year}-${date.month}-${date.day}";
    return ret;
  }

  Future<bool> showAlertDialog(BuildContext context) async {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancelar"),
      onPressed: () {
        Navigator.of(context).pop(false);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Continuar"),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("AlertDialog"),
      content: const Text("Desea borrar esta ruta? Esto no se puede deshacer."),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    var res = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    return (res == true);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: ValueListenableBuilder(
            valueListenable: Hive.box('trips').listenable(),
            builder: (context, box, widget) {
              var trips = box.values.toList();
              // box.clear();

              if (trips.isNotEmpty) {
                return ListView.builder(
                  itemBuilder: (context, i) {
                    var k = box.keys.toList()[i];
                    Trip trip = Trip.fromJsonString(trips[i]);
                    return InkWell(
                      onTap: () {
                        // print("Mapa de ${trip.id}");
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MapScreen(id: trip.id)));
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(trip.toString()),
                          trailing: tracking && k == trackingPos
                              ? IconButton(
                                  icon: const Icon(Icons.pin_drop),
                                  onPressed: () {},
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    var res = await showAlertDialog(context);
                                    if (res) {
                                      box.deleteAt(i);
                                    }
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                  itemCount: trips.length,
                );
              } else {
                return const Center(
                  child: Text("No hay viajes registrados"),
                );
              }
            }),
        floatingActionButton: tracking
            ? FloatingActionButton(
                onPressed: () async {
                  Locator().stopTracking();
                  var trip = Trip.fromJsonString(trips.get(trackingPos));
                  trip.endTime = DateTime.now();
                  await trips.put(trackingPos, trip.toJsonString());
                  setState(() {
                    tracking = false;
                    trackingPos = -1;
                  });
                },
                tooltip: 'Stop Track',
                child: const Icon(Icons.stop),
              )
            : FloatingActionButton(
                onPressed: () async {
                  await Locator().initGPS();
                  var trip = Trip(DateTime.now());
                  Locator().startTracking(trip.id);
                  trackingPos = await trips.add(trip.toJsonString());
                  setState(() {
                    tracking = true;
                  });
                },
                tooltip: 'New Track',
                child: const Icon(Icons.play_arrow),
              ),
      ),
    );
  }
}
