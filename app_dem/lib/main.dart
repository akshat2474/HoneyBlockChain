import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
      title: 'IDR Prototype Phase 3',
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
  // Location and Navigation State
  Position? _realGpsPosition;
  LatLng? _destination;
  LatLng? _displayedPosition;
  double _currentHeadingDeg = 0.0;
  
  final List<LatLng> _gnssTrajectory = [];
  final List<LatLng> _drTrajectory = [];
  
  bool _gnssActive = true;
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
  String _backendIp = '192.168.1.100'; 
  String _connectionStatus = 'Disconnected';
  Timer? _dataSendTimer;
  
  // Debug info from backend
  String _backendDebugInfo = '';

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
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Use a small distance filter to avoid jitter when standing still
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Force update on any movement
      ),
    ).listen((Position position) {
      _realGpsPosition = position;
      
      if (_gnssActive) {
        setState(() {
          final latLng = LatLng(position.latitude, position.longitude);
          _displayedPosition = latLng;
          
          // Use GPS heading if it is providing valid data
          if (position.heading > 0) {
            _currentHeadingDeg = position.heading;
          } else if (_magnetometerValues != null) {
            // Fallback to rough magnetometer compass heading when stationary
            _currentHeadingDeg = (math.atan2(-_magnetometerValues![0], _magnetometerValues![1]) * 180 / math.pi);
          }
          
          _gnssTrajectory.add(latLng);
          
          _mapController.move(latLng, _mapController.camera.zoom);
        });
      }
    });
  }
  
  double _calculateDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  void _startSensors() {
    _streamSubscriptions.add(
      accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          _accelerometerValues = <double>[event.x, event.y, event.z];
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
          
          if (_gnssActive && (_realGpsPosition == null || _realGpsPosition!.heading <= 0)) {
             _currentHeadingDeg = (math.atan2(-event.x, event.y) * 180 / math.pi);
          }
        },
        cancelOnError: true,
      ),
    );

    // Update UI every 50ms for smooth rotation (20fps)
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
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

      _channel!.stream.listen(
        (message) {
          _handleBackendMessage(message.toString());
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

      // Send data periodically at 5Hz
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
  
  void _handleBackendMessage(String message) {
    try {
      final jsonResponse = json.decode(message);
      
      if (!_gnssActive && jsonResponse['mode'] == 'DEAD_RECKONING') {
        final estLoc = jsonResponse['estimated_location'];
        final debug = jsonResponse['debug'];
        
        if (estLoc != null) {
          final latLng = LatLng(estLoc['lat'], estLoc['lon']);
          setState(() {
            _displayedPosition = latLng;
            
            _drTrajectory.add(latLng);
            
            _mapController.move(latLng, _mapController.camera.zoom);
          });
        }
        
        if (debug != null) {
          setState(() {
             _currentHeadingDeg = debug['heading_deg'];
             _backendDebugInfo = 'Speed: ${debug['speed']} m/s | Head: ${_currentHeadingDeg.toStringAsFixed(1)}°';
          });
        }
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  void _sendDataToBackend() {
    if (_channel != null && _connectionStatus.startsWith('Connected')) {
      final data = {
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "gnss_active": _gnssActive,
        "location": _realGpsPosition != null ? {
          "lat": _realGpsPosition!.latitude,
          "lon": _realGpsPosition!.longitude,
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
              onPressed: () => Navigator.pop(context),
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
  
  void _toggleBlackout() {
    setState(() {
      _gnssActive = !_gnssActive;
      
      if (!_gnssActive) {
        if (_displayedPosition != null) {
          _drTrajectory.add(_displayedPosition!);
        }
      } else {
        _backendDebugInfo = '';
      }
    });
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
        title: const Text('IDR Phase 3'),
        backgroundColor: _gnssActive 
            ? Theme.of(context).colorScheme.inversePrimary 
            : Colors.redAccent,
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
          if (!_gnssActive)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'WARNING: GNSS SIGNAL LOST - USING DEAD RECKONING',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _displayedPosition ?? const LatLng(0, 0),
                initialZoom: 19.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _destination = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app_dem',
                ),
                PolylineLayer(
                  polylines: [
                    // Line to Destination
                    if (_destination != null && _displayedPosition != null)
                      Polyline(
                        points: [_displayedPosition!, _destination!],
                        strokeWidth: 3.0,
                        color: Colors.green,
                      ),
                    // Blue line for real GNSS path
                    Polyline(
                      points: _gnssTrajectory,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                    // Red line for DR path
                    Polyline(
                      points: _drTrajectory,
                      strokeWidth: 4.0,
                      color: Colors.red,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Destination Marker
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                    // Current Position Marker
                    if (_displayedPosition != null)
                      Marker(
                        point: _displayedPosition!,
                        width: 40,
                        height: 40,
                        child: Transform.rotate(
                          angle: _currentHeadingDeg * (math.pi / 180),
                          child: Icon(
                            Icons.navigation,
                            color: _gnssActive ? Colors.blue : Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleBlackout,
                    icon: Icon(_gnssActive ? Icons.gps_off : Icons.gps_fixed),
                    label: Text(_gnssActive ? 'Simulate GNSS Blackout' : 'Restore GNSS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gnssActive ? Colors.red.shade100 : Colors.green.shade100,
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _gnssTrajectory.clear();
                      _drTrajectory.clear();
                      _destination = null;
                      // Keep current position if available
                      if (_displayedPosition != null) {
                        if (_gnssActive) {
                          _gnssTrajectory.add(_displayedPosition!);
                        } else {
                          _drTrajectory.add(_displayedPosition!);
                        }
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    minimumSize: const Size(0, 50),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.black87),
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (!_gnssActive && _backendDebugInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          'DR Info: $_backendDebugInfo',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_displayedPosition != null)
                      _buildInfoRow(
                        'Display Lat/Lon:',
                        '${_displayedPosition!.latitude.toStringAsFixed(6)}, ${_displayedPosition!.longitude.toStringAsFixed(6)}',
                        _gnssActive ? Colors.blue : Colors.red,
                      ),
                    _buildInfoRow(
                        'Heading:',
                        '${_currentHeadingDeg.toStringAsFixed(1)}°',
                        Colors.black,
                      ),
                    const Divider(),
                    const Text('Live Sensor Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildSensorRow('Accel', _accelerometerValues),
                    _buildSensorRow('Gyro', _gyroscopeValues),
                    _buildSensorRow('Mag', _magnetometerValues),
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
