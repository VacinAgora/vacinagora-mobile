import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/src/types/marker_updates.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

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

Marker _createMarker(dynamic place) {
  debugPrint(place.toString());
  return Marker(
    markerId: _createMarkerId(place['placeId']),
    position: LatLng(place['latitude'], place['longitude']),
    infoWindow: InfoWindow(title: place['placeId'], snippet: '*'),
    // onTap: () {
    //   _onMarkerTapped(markerId);
    // },
  );
}

Future<http.Response> sendPosition(Position position) {
  return http.post(
    Uri.http('192.168.0.13:9000', '/kafka/publish/positions'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, Object>{
      'userId': "1234",
      'lat': position.latitude,
      'lng': position.longitude
    }),
  );
}

class MapSampleState extends State<MapSample> {

  // Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Set<Marker> markers = Set();

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
              // debugPrint('lat: ${position.latitude}, long: ${position.longitude}');
              sendPosition(position);
            })
        );

    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        myLocationEnabled: true,
        onCameraIdle: () {
          _updateMap();
        },
        markers: markers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: Text('Vou Vacinar'),
        icon: Icon(Icons.location_on),
      ),
    );
  }

  Future<List<dynamic>> getPositions(LatLngBounds bounds) async {
    var queryParameters = {
      'swLat': '${bounds.southwest.latitude}',
      'swLng': '${bounds.southwest.longitude}',
      'neLat': '${bounds.northeast.latitude}',
      'neLng': '${bounds.northeast.longitude}'
    };
    return http.get(
        Uri.http('192.168.0.13:9000', '/places/', queryParameters),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        }
    ).then((value) => json.decode(value.body));
  }

  void _updateMap() async {
    final GoogleMapController controller = await _controller.future;
    var visibleRegion = controller.getVisibleRegion();

    // Map<MarkerId, Marker> newMarkers =  await visibleRegion
    List<Marker> updatedMarkers = await visibleRegion
        .then((bounds) => getPositions(bounds))
        .then((places) => places.map((place) => _createMarker(place)).toList());
        // .then((markersList) => Map<MarkerId, Marker>.fromIterable(markersList, key: (e) => e.markerId, value: (e) => e));

    setState(() {
      // markers = [];
      markers = Set();
      markers = Set.from(updatedMarkers);
    });
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

    return Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );
  }
}