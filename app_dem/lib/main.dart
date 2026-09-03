import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDR Prototype Phase 2',
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

  // WebSocket
  WebSocketChannel? _channel;
  String _backendIp = '192.168.1.100'; // Default, can be changed
  String _connectionStatus = 'Disconnected';
  String _lastServerResponse = 'None';
  Timer? _dataSendTimer;

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

    setState(() {
      _locationStatus = 'GNSS Active. Waiting for fix...';
    });
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _locationStatus = 'GNSS Active';
        
        final latLng = LatLng(position.latitude, position.longitude);
        _trajectory.add(latLng);
        
        _mapController.move(latLng, 18.0);
      });
    });
  }

  void _startSensors() {
    _streamSubscriptions.add(
      accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          _accelerometerValues = <double>[event.x, event.y, event.z];
          // We don't call setState here to avoid UI stuttering with 100Hz updates
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          _gyroscopeValues = <double>[event.x, event.y, event.z];
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          _magnetometerValues = <double>[event.x, event.y, event.z];
        },
        cancelOnError: true,
      ),
    );

    // Update UI every 500ms instead of every sensor event
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _connectWebSocket() {
    if (_channel != null) {
      _channel!.sink.close();
    }

    final wsUrl = Uri.parse('ws://$_backendIp:8000/ws');
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      setState(() {
        _connectionStatus = 'Connected to $_backendIp';
      });

      // Listen for messages from the backend
      _channel!.stream.listen(
        (message) {
          setState(() {
            _lastServerResponse = message.toString();
          });
        },
        onError: (error) {
          setState(() {
            _connectionStatus = 'Error: $error';
            _channel = null;
          });
        },
        onDone: () {
          setState(() {
            _connectionStatus = 'Disconnected';
            _channel = null;
          });
        },
      );

      // Start sending data periodically
      _dataSendTimer?.cancel();
      _dataSendTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _sendDataToBackend();
      });

    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
      });
    }
  }

  void _sendDataToBackend() {
    if (_channel != null && _connectionStatus.startsWith('Connected')) {
      final data = {
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "gnss_active": _gnssActive,
        "location": _currentPosition != null ? {
          "lat": _currentPosition!.latitude,
          "lon": _currentPosition!.longitude,
        } : null,
        "accel": _accelerometerValues,
        "gyro": _gyroscopeValues,
        "mag": _magnetometerValues,
      };
      _channel!.sink.add(json.encode(data));
    }
  }

  void _showIpDialog() {
    final TextEditingController ipController = TextEditingController(text: _backendIp);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Backend IP'),
          content: TextField(
            controller: ipController,
            decoration: const InputDecoration(hintText: "192.168.x.x"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _backendIp = ipController.text;
                });
                Navigator.pop(context);
                _connectWebSocket();
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _dataSendTimer?.cancel();
    _channel?.sink.close();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IDR Phase 2'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            onPressed: _showIpDialog,
            tooltip: 'Connect Backend',
          )
        ],
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
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Backend Connection UI
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Backend:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            _connectionStatus,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: _connectionStatus.startsWith('Connected') ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
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
                    const SizedBox(height: 4),
                    _buildSensorRow('Accel', _accelerometerValues),
                    _buildSensorRow('Gyro', _gyroscopeValues),
                    _buildSensorRow('Mag', _magnetometerValues),
                    const Divider(),
                    const Text('Latest Server Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _lastServerResponse,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Text('$label: Waiting...'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Text(
        '$label: X:${values[0].toStringAsFixed(1)} Y:${values[1].toStringAsFixed(1)} Z:${values[2].toStringAsFixed(1)}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
