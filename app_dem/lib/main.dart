import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDR Prototype Phase 1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Location
  Position? _currentPosition;
  final List<LatLng> _trajectory = [];
  bool _gnssActive = true;
  String _locationStatus = 'Initializing...';
  StreamSubscription<Position>? _positionStream;

  // Sensors
  List<double>? _accelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  // Map Controller
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartLocation();
    _startSensors();
  }

  Future<void> _checkPermissionsAndStartLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationStatus = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationStatus = 'Location permissions are permanently denied.';
      });
      return;
    }

    // Permissions are granted, start listening
    setState(() {
      _locationStatus = 'GNSS Active. Waiting for fix...';
    });
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // update every 1 meter
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _locationStatus = 'GNSS Active';
        
        final latLng = LatLng(position.latitude, position.longitude);
        _trajectory.add(latLng);
        
        // Recenter map
        _mapController.move(latLng, 18.0);
      });
    });
  }

  void _startSensors() {
    _streamSubscriptions.add(
      accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          debugPrint("Accelerometer error: $e");
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          // Ignore if gyro not supported perfectly on emulator
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          // Ignore
        },
        cancelOnError: true,
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IDR Prototype - Phase 1'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _trajectory.isNotEmpty
                    ? _trajectory.last
                    : const LatLng(0, 0),
                initialZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app_dem',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trajectory,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                if (_trajectory.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _trajectory.last,
                        width: 20,
                        height: 20,
                        child: const Icon(
                          Icons.circle,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Data Section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Operating Mode:', _gnssActive ? 'GNSS ACTIVE' : 'GNSS BLACKOUT', Colors.green),
                    _buildInfoRow('GNSS Status:', _locationStatus, Colors.black87),
                    if (_currentPosition != null)
                      _buildInfoRow(
                        'Lat/Lon:',
                        '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        Colors.black87,
                      ),
                    const Divider(),
                    const Text('Live Sensor Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildSensorRow('Accel (m/s²)', _accelerometerValues),
                    _buildSensorRow('Gyro (rad/s)', _gyroscopeValues),
                    _buildSensorRow('Mag (μT)', _magnetometerValues),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String label, List<double>? values) {
    if (values == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text('$label: Waiting for data...'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        '$label: X: ${values[0].toStringAsFixed(2)}, Y: ${values[1].toStringAsFixed(2)}, Z: ${values[2].toStringAsFixed(2)}',
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
