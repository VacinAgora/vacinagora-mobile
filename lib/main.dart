import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

MarkerId _createMarkerId(String id) {
  return MarkerId(id);
}

Marker _createMarker(MarkerId id, LatLng position, String title) {
  return Marker(
    markerId: id,
    position: position,
    infoWindow: InfoWindow(title: title, snippet: '*'),
    // onTap: () {
    //   _onMarkerTapped(markerId);
    // },
  );
}

class MapSampleState extends State<MapSample> {
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{
    _createMarkerId("1"): _createMarker(_createMarkerId("1"), LatLng(-5.8268322, -35.21461), "Arena das Dunas"),
    _createMarkerId("2"): _createMarker(_createMarkerId("2"), LatLng(-5.8370091,-35.2199315), "UBS Candelária"),
    _createMarkerId("3"): _createMarker(_createMarkerId("3"), LatLng(-5.8616649,-35.1949278), "Universidade Potiguar - Unidade Roberto Freire"),
    _createMarkerId("4"): _createMarker(_createMarkerId("4"), LatLng(-5.7333716,-35.2560076), "Ginásio Municipal Nélio Dias"),
    _createMarkerId("5"): _createMarker(_createMarkerId("5"), LatLng(-5.8409889,-35.2113981), "Via Direta"),
    _createMarkerId("6"): _createMarker(_createMarkerId("6"), LatLng(-5.5790832,-36.919452), "UBS Dom Elizeu"),
  };

  // final Marker marker = Marker(
  //   markerId: MarkerId("1"),
  //   position: LatLng(-5.8268322, -35.21461),
  //   infoWindow: InfoWindow(title: "Arena das Dunas", snippet: '*'),
  //   // onTap: () {
  //   //   _onMarkerTapped(markerId);
  //   // },
  // );

  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-5.812757, -35.255127),
    zoom: 14,
  );

  static final CameraPosition _kLake = CameraPosition(
      target: LatLng(37.43296265331129, -122.08832357078792),
      zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    this._determinePosition()
        .then((positionStream) => positionStream.listen(
            (Position position) {
              debugPrint('lat: ${position.latitude}, long: ${position.longitude}');
            })
        );

    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: Set<Marker>.of(markers.values),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: Text('Vou Vacinar'),
        icon: Icon(Icons.location_on),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<Stream<Position>> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error(
            'Location permissions are denied');
      }
    }

    // // When we reach here, permissions are granted and we can
    // // continue accessing the position of the device.
    // return await Geolocator.getCurrentPosition();

    return Geolocator.getPositionStream();
  }
}