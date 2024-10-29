import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'package:animated_marker/animated_marker.dart';

/// Stream of mock data positions for the AnimatedMarker widget:
final List<LatLng> mockPositions = [
  const LatLng(37.77483, -122.41942),
  const LatLng(37.76703, -122.40124),
  const LatLng(37.76651, -122.42206),
];
final List<LatLng> mockPositionsStatic = [
  const LatLng(37.75483, -122.42942),
  const LatLng(37.75551, -122.41106),
];

final Stream<LatLng> positionStream = Stream.periodic(
  const Duration(seconds: 3),
  (computationCount) {
    final index = computationCount % mockPositions.length;
    return mockPositions.elementAt(index);
  },
);

Future<void> main() async {
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Switching to the legacy Google Maps renderer due to a known '
        'fickering bug with the latest renderer.');
    await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.legacy);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  /// Note: This example assumes you already have google_maps_flutter
  /// and animated_marker packages added to your project as dependencies.
  /// Also, remember to replace 'your_api_key' with your actual
  /// Google Maps API Key in your AndroidManifest.xml file
  /// or Info.plist file for Android and iOS respectively.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final staticMarkers = {
      for (int i = 0; i < mockPositionsStatic.length; i++)
        Marker(
          markerId: MarkerId('static-$i'),
          position: mockPositionsStatic.elementAt(i),
          infoWindow: InfoWindow(title: 'Static Marker $i'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
    };

    return MaterialApp(
      home: Scaffold(
        /// implementation with a StreamBuilder using the above stream:
        body: StreamBuilder<LatLng>(
          stream: positionStream, // use the stream in the builder
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container(); // handle no data

            final markers = {
              Marker(
                markerId: const MarkerId('uniqueMarkerId'),
                position: snapshot.data!,
                infoWindow: const InfoWindow(title: 'Animated Marker'),
              )
            };

            return AnimatedMarker(
              staticMarkers: staticMarkers,
              animatedMarkers: markers,
              duration:
                  const Duration(seconds: 3), // change the animation duration
              builder: (context, animatedMarkers) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: mockPositions.first,
                    zoom: 13,
                  ),
                  markers: animatedMarkers,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
