import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Currentloc extends StatefulWidget {
  @override
  _CurrentlocState createState() => _CurrentlocState();
}

class _CurrentlocState extends State<Currentloc> {
  StreamSubscription<Position> positionStream;
  @override
  void initState() {
    super.initState();
    _determinePosition().then((v) => print(v));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: <Widget>[
      Align(
        alignment: Alignment.center,
        child: StreamBuilder<Position>(
            stream: Geolocator.getPositionStream(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.active:
                  print(snapshot.data.latitude.toString() +
                      ',' +
                      snapshot.data.longitude.toString());
                  return Text(snapshot.hasData
                      ? snapshot.data.latitude.toString() +
                          ',' +
                          snapshot.data.longitude.toString()
                      : '');
                  break;
                default:
                  return Text('hello');
              }
            }),
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: FlatButton(
          color: Colors.blue,
          child: Text('GOTO MAP'),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) => MapView()));
          },
        ),
      ),
    ]));
  }

  @override
  void dispose() {
    if (positionStream != null) {
      positionStream.cancel();
      positionStream = null;
    }

    super.dispose();
  }
}


class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = Set();
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(11.0618617, 76.0683918),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => Currentloc()));
          },
        ),
      ),
      body: Stack(children: <Widget>[
        GoogleMap(
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          markers: markers,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          onTap: (latlang) {
            setState(() {
              markers.add(Marker(
                  markerId: MarkerId(latlang.latitude.toString() +
                      latlang.longitude.toString()),
                  position: LatLng(latlang.latitude, latlang.longitude)));
            });
          },
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 80),
            child: FloatingActionButton.extended(
              heroTag: 'flb1',
              onPressed: () {
                setState(() {
                  markers.clear();
                });
              },
              label: Text('Clear locations'),
            ),
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'flb2',
        onPressed: () {},
        label: Text('Confirm Location'),
        icon: Icon(Icons.location_on),
      ),
    );
  }
}


Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permantly denied, we cannot request permissions.');
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return Future.error(
          'Location permissions are denied (actual value: $permission).');
    }
  }

  return await Geolocator.getCurrentPosition();
}