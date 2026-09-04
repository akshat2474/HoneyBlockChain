import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ---------------------------------------------------------------------------
// Comparison report data model
// ---------------------------------------------------------------------------
class _ComparisonReport {
  final Duration sessionDuration;
  final double drFinalError;    // metres: DR end-point vs last-known GNSS fix
  final double rawFinalError;   // metres: raw HW end-point vs last-known GNSS fix
  final double drMaxDrift;      // metres: max distance any DR point strayed
  final double rawMaxDrift;     // metres: max distance any raw point strayed
  final double drPathLength;    // metres: total DR path length
  final double rawPathLength;   // metres: total raw path length
  final int pointCount;         // number of 5 Hz samples collected

  const _ComparisonReport({
    required this.sessionDuration,
    required this.drFinalError,
    required this.rawFinalError,
    required this.drMaxDrift,
    required this.rawMaxDrift,
    required this.drPathLength,
    required this.rawPathLength,
    required this.pointCount,
  });

  /// Positive means DR was more accurate than raw. Null when rawFinalError is 0.
  double? get improvementPct {
    if (rawFinalError <= 0) return null;
    return (rawFinalError - drFinalError) / rawFinalError * 100;
  }
}

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
  double _currentHeadingDeg = 0.0;   // raw heading from sensors/backend
  double _displayedHeadingDeg = 0.0; // smoothed heading for the arrow (no jitter)
  
  final List<LatLng> _gnssTrajectory = [];
  final List<LatLng> _drTrajectory = [];

  // ── Raw Hardware Trajectory (naive, no backend correction) ───────────────
  final List<LatLng> _rawHwTrajectory = [];
  LatLng?  _rawHwPosition;       // current raw HW estimated position
  double   _rawHwHeadingDeg = 0.0;

  // ── DR Session Bookkeeping ───────────────────────────────────────────────
  LatLng?   _drStartPosition;   // last GNSS fix when DR mode began
  DateTime? _drStartTime;
  Timer?    _rawHwTimer;        // 5 Hz raw integration timer

  // ── Static Accuracy Test ─────────────────────────────────────────────────
  bool      _staticTestActive  = false;
  LatLng?   _staticTestOrigin;  // where the phone was when test started
  DateTime? _staticTestStart;
  Timer?    _staticTestTimer;
  double    _staticTestMaxDrift = 0.0;
  double    _staticTestCurrentDrift = 0.0;
  double    _staticTestCurrentVariance = 0.0;
  bool      _staticTestZupt    = false;
  // Drift samples: list of (elapsed_seconds, drift_m, variance, zupt)
  final List<Map<String, dynamic>> _staticTestSamples = [];
  static const int _staticTestDurationSec = 60;

  bool _gnssActive = true;
  StreamSubscription<Position>? _positionStream;

  // Sensors
  List<double>? _accelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  bool _simulateWalking = false; // toggles fake accelerometer data

  List<double>? get _effectiveAccelValues {
    if (_simulateWalking) {
      // Simulates brisk walking (total mag = 11.5 -> variance = 1.69 m/s^2)
      return [0.0, 0.0, 11.5];
    }
    return _accelerometerValues;
  }

  // Map Controller
  final MapController _mapController = MapController();

  // WebSocket
  WebSocketChannel? _channel;
  String _backendIp = '192.168.1.100'; 
  String _connectionStatus = 'Disconnected';
  Timer? _dataSendTimer;
  Timer? _reconnectTimer;
  
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable GPS.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. The app cannot track your position.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied. Enable it in app settings.'), backgroundColor: Colors.red, duration: Duration(seconds: 5)),
        );
      }
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
    const Distance distance = Distance(roundResult: false);
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  // =========================================================================
  // Raw Hardware Integration (naive, 5 Hz, no backend correction)
  // =========================================================================

  /// Estimates a scalar speed (m/s) from raw accelerometer magnitude.
  /// We subtract gravity (≈9.81) and treat the remainder as linear motion.
  double _estimateRawSpeedMs() {
    final accel = _effectiveAccelValues;
    if (accel == null) return 0.0;
    final ax = accel[0];
    final ay = accel[1];
    final az = accel[2];
    final totalMag = math.sqrt(ax * ax + ay * ay + az * az);
    // Deviation from gravity = linear acceleration proxy
    final linearAccel = (totalMag - 9.81).abs();
    // Clamp: standing ≈ 0–0.3, walking ≈ 0.5–2, running ≈ 2–4 m/s
    return linearAccel.clamp(0.0, 4.0);
  }

  /// Called at 5 Hz while DR mode is active. Updates _rawHwPosition using
  /// raw magnetometer heading and raw accelerometer speed (no Kalman filter).
  void _updateRawHardwarePosition() {
    if (_rawHwPosition == null) return;

    const double dt = 0.2; // seconds per tick

    // Heading: raw magnetometer compass, no tilt correction
    if (_magnetometerValues != null) {
      _rawHwHeadingDeg =
          math.atan2(-_magnetometerValues![0], _magnetometerValues![1]) *
              180 /
              math.pi;
    }

    final double speedMs  = _estimateRawSpeedMs();
    final double headingRad = _rawHwHeadingDeg * math.pi / 180.0;
    final double distM    = speedMs * dt;

    // Convert displacement to lat/lon delta
    const double metersPerDegLat = 111320.0;
    final double metersPerDegLon =
        111320.0 * math.cos(_rawHwPosition!.latitude * math.pi / 180.0);

    final double dLat = (distM * math.cos(headingRad)) / metersPerDegLat;
    final double dLon = (distM * math.sin(headingRad)) / metersPerDegLon;

    final newPos = LatLng(
      _rawHwPosition!.latitude  + dLat,
      _rawHwPosition!.longitude + dLon,
    );

    setState(() {
      _rawHwPosition = newPos;
      _rawHwTrajectory.add(newPos);
    });
  }

  // =========================================================================
  // Comparison Report Computation
  // =========================================================================
  _ComparisonReport _computeReport() {
    final ref = _drStartPosition!; // last GNSS fix = ground truth reference

    // Final-point errors
    final drEnd  = _drTrajectory.isNotEmpty   ? _drTrajectory.last   : ref;
    final rawEnd = _rawHwTrajectory.isNotEmpty ? _rawHwTrajectory.last : ref;
    final drFinalError  = _calculateDistance(ref, drEnd);
    final rawFinalError = _calculateDistance(ref, rawEnd);

    // Max drift from reference at any point
    double drMax = 0, rawMax = 0;
    for (final p in _drTrajectory) {
      final d = _calculateDistance(ref, p);
      if (d > drMax) drMax = d;
    }
    for (final p in _rawHwTrajectory) {
      final d = _calculateDistance(ref, p);
      if (d > rawMax) rawMax = d;
    }

    // Total path lengths
    double drLen = 0, rawLen = 0;
    for (int i = 1; i < _drTrajectory.length; i++) {
      drLen += _calculateDistance(_drTrajectory[i - 1], _drTrajectory[i]);
    }
    for (int i = 1; i < _rawHwTrajectory.length; i++) {
      rawLen += _calculateDistance(_rawHwTrajectory[i - 1], _rawHwTrajectory[i]);
    }

    final duration = _drStartTime != null
        ? DateTime.now().difference(_drStartTime!)
        : Duration.zero;

    return _ComparisonReport(
      sessionDuration: duration,
      drFinalError:    drFinalError,
      rawFinalError:   rawFinalError,
      drMaxDrift:      drMax,
      rawMaxDrift:     rawMax,
      drPathLength:    drLen,
      rawPathLength:   rawLen,
      pointCount:      _drTrajectory.length,
    );
  }

  // =========================================================================
  // Comparison Report Dialog
  // =========================================================================
  void _showComparisonReport(_ComparisonReport report) {
    final imp      = report.improvementPct;
    final impColor = (imp != null && imp >= 0)
        ? Colors.green.shade700
        : Colors.red.shade700;
    final impText = imp != null
        ? '${imp >= 0 ? '+' : ''}${imp.toStringAsFixed(1)}%'
        : 'N/A';

    showDialog(
      context: context,
      barrierDismissible: false, // stays until user taps OK
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('DR vs Raw Hardware', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Session summary
              _reportSummaryRow('Session Duration',
                  _formatDuration(report.sessionDuration)),
              _reportSummaryRow(
                  'Samples Collected', '${report.pointCount} @ 5 Hz'),
              const Divider(height: 20),

              // Comparison table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FlexColumnWidth(1.4),
                  2: FlexColumnWidth(1.4),
                },
                children: [
                  _tableHeader(),
                  _tableRow(
                    'Final Error',
                    '${report.drFinalError.toStringAsFixed(1)} m',
                    '${report.rawFinalError.toStringAsFixed(1)} m',
                    drBetter: report.drFinalError <= report.rawFinalError,
                  ),
                  _tableRow(
                    'Max Drift',
                    '${report.drMaxDrift.toStringAsFixed(1)} m',
                    '${report.rawMaxDrift.toStringAsFixed(1)} m',
                    drBetter: report.drMaxDrift <= report.rawMaxDrift,
                  ),
                  _tableRow(
                    'Path Length',
                    '${report.drPathLength.toStringAsFixed(1)} m',
                    '${report.rawPathLength.toStringAsFixed(1)} m',
                    drBetter: null, // neutral — not a quality metric
                  ),
                ],
              ),

              const Divider(height: 20),

              // Overall improvement
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Overall Improvement:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(impText,
                      style: TextStyle(
                          color: impColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                (imp != null && imp >= 0)
                    ? 'DR reduced final error vs raw hardware by $impText.'
                    : 'Raw hardware performed better than DR this session.',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),

              // Legend
              _dialogLegendRow(Colors.red,    'Red line  – AI-corrected DR path'),
              _dialogLegendRow(Colors.orange, 'Orange line – Raw hardware path'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ── Dialog helper widgets ─────────────────────────────────────────────────
  Widget _reportSummaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
      );

  TableRow _tableHeader() => TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: [
          _tableCell('Metric',  bold: true),
          _tableCell('DR (AI)', bold: true, color: Colors.red.shade700),
          _tableCell('Raw HW',  bold: true, color: Colors.orange.shade800),
        ],
      );

  TableRow _tableRow(String label, String drVal, String rawVal,
      {bool? drBetter}) {
    final drColor = drBetter == null
        ? Colors.black
        : (drBetter ? Colors.green.shade700 : Colors.red.shade700);
    final rawColor = drBetter == null
        ? Colors.black
        : (drBetter ? Colors.red.shade700 : Colors.green.shade700);
    return TableRow(children: [
      _tableCell(label),
      _tableCell(drVal,  color: drColor,  bold: drBetter == true),
      _tableCell(rawVal, color: rawColor, bold: drBetter == false),
    ]);
  }

  Widget _tableCell(String text,
      {bool bold = false, Color color = Colors.black}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
            fontSize: 12,
          ),
        ),
      );

  Widget _dialogLegendRow(Color color, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(width: 18, height: 4, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}h ' : ''}${m}m ${s}s';
  }


  // =========================================================================
  // Sensors
  // =========================================================================
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
      if (mounted) {
        setState(() {
          // Low-pass filter: 85% old value + 15% new raw reading.
          // This makes the arrow glide smoothly instead of snapping/jittering.
          // Handle wraparound (e.g. 359° -> 1° should go forward, not spin 358°).
          double diff = _currentHeadingDeg - _displayedHeadingDeg;
          // Normalize diff to [-180, 180]
          if (diff > 180) diff -= 360;
          if (diff < -180) diff += 360;
          _displayedHeadingDeg = (_displayedHeadingDeg + diff * 0.15) % 360;
        });
      }
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
            _connectionStatus = 'Disconnected — retrying...';
            _channel = null;
          });
          // Auto-reconnect after 5 seconds
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(const Duration(seconds: 5), () {
            if (mounted && _channel == null) {
              _connectWebSocket();
            }
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
          final zupt = debug['zupt'] == true;
          final variance = (debug['accel_var'] as num?)?.toDouble() ?? 0.0;
          setState(() {
             _currentHeadingDeg = debug['heading_deg'];
             _backendDebugInfo =
                 'Speed: ${debug['speed']} m/s | Head: ${_currentHeadingDeg.toStringAsFixed(1)}° | '
                 'Var: ${debug['accel_var']} | ${zupt ? '🔴 STATIONARY (ZUPT)' : '🟢 MOVING'}';
             // Feed live values into static test tracker
             if (_staticTestActive) {
               _staticTestCurrentVariance = variance;
               _staticTestZupt = zupt;
             }
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
        "accel": _effectiveAccelValues,
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
  
  // =========================================================================
  // Static Accuracy Test
  // =========================================================================

  void _startStaticTest() {
    if (_displayedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Waiting for GPS fix before static test can start.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // Enter DR mode first so backend starts sending estimates
    if (_gnssActive) _toggleBlackout();

    setState(() {
      _staticTestActive   = true;
      _staticTestOrigin   = _displayedPosition;
      _staticTestStart    = DateTime.now();
      _staticTestMaxDrift = 0.0;
      _staticTestCurrentDrift   = 0.0;
      _staticTestCurrentVariance = 0.0;
      _staticTestZupt    = false;
      _staticTestSamples.clear();
    });

    // Sample drift every second for _staticTestDurationSec seconds
    _staticTestTimer?.cancel();
    _staticTestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }

      final elapsed = timer.tick; // seconds elapsed
      final currentPos = _displayedPosition;
      if (currentPos == null || _staticTestOrigin == null) return;

      final drift = _calculateDistance(_staticTestOrigin!, currentPos);

      setState(() {
        _staticTestCurrentDrift = drift;
        if (drift > _staticTestMaxDrift) _staticTestMaxDrift = drift;
        _staticTestSamples.add({
          'sec':      elapsed,
          'drift':    drift,
          'variance': _staticTestCurrentVariance,
          'zupt':     _staticTestZupt,
        });
      });

      if (elapsed >= _staticTestDurationSec) {
        timer.cancel();
        _stopStaticTest(autoFinished: true);
      }
    });
  }

  void _stopStaticTest({bool autoFinished = false}) {
    _staticTestTimer?.cancel();
    _staticTestTimer = null;

    final samples = List<Map<String, dynamic>>.from(_staticTestSamples);
    final maxDrift = _staticTestMaxDrift;
    final origin   = _staticTestOrigin;

    setState(() {
      _staticTestActive = false;
      // Restore GNSS if we auto-entered DR
      if (!_gnssActive) _toggleBlackout();
    });

    if (samples.isNotEmpty && origin != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showStaticTestReport(samples, maxDrift, autoFinished);
      });
    }
  }

  void _showStaticTestReport(
    List<Map<String, dynamic>> samples,
    double maxDrift,
    bool completed,
  ) {
    final duration   = samples.last['sec'] as int;
    final finalDrift = samples.last['drift'] as double;

    // Average variance and ZUPT rate
    final avgVariance = samples.isEmpty
        ? 0.0
        : samples.map((s) => s['variance'] as double).reduce((a, b) => a + b) /
            samples.length;
    final zuptRate = samples.isEmpty
        ? 0.0
        : samples.where((s) => s['zupt'] == true).length / samples.length * 100;

    // Drift rate in m/min (only fair if test ran > 10s)
    final driftRate = duration >= 10
        ? (maxDrift / duration * 60)
        : null;

    // Verdict
    final String verdict;
    final Color verdictColor;
    if (maxDrift < 1.0) {
      verdict = '✅ EXCELLENT — sub-metre stationary accuracy';
      verdictColor = Colors.green.shade700;
    } else if (maxDrift < 3.0) {
      verdict = '✅ GOOD — typical GNSS-grade accuracy';
      verdictColor = Colors.green.shade600;
    } else if (maxDrift < 8.0) {
      verdict = '⚠️ FAIR — some phantom drift detected';
      verdictColor = Colors.orange.shade700;
    } else {
      verdict = '❌ POOR — ZUPT threshold needs tuning';
      verdictColor = Colors.red.shade700;
    }

    // Build drift-over-time table (show one row per 5s to keep it readable)
    final tableRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: [
          _stCell('Time (s)', bold: true),
          _stCell('Drift (m)', bold: true),
          _stCell('Var',       bold: true),
          _stCell('ZUPT',      bold: true),
        ],
      ),
      ...samples.where((s) => (s['sec'] as int) % 5 == 0 || s == samples.last).map((s) {
        final d = (s['drift'] as double);
        final dColor = d < 1.0
            ? Colors.green.shade700
            : d < 3.0 ? Colors.orange.shade700 : Colors.red.shade700;
        return TableRow(children: [
          _stCell('${s['sec']}s'),
          _stCell('${d.toStringAsFixed(2)} m', color: dColor),
          _stCell((s['variance'] as double).toStringAsFixed(2)),
          _stCell(s['zupt'] == true ? '🔴' : '🟢'),
        ]);
      }),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.science, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              completed ? 'Static Test Complete' : 'Static Test Stopped',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary metrics
              _reportSummaryRow('Duration',     '${duration}s'),
              _reportSummaryRow('Max Drift',    '${maxDrift.toStringAsFixed(2)} m'),
              _reportSummaryRow('Final Drift',  '${finalDrift.toStringAsFixed(2)} m'),
              if (driftRate != null)
                _reportSummaryRow('Drift Rate',
                    '${driftRate.toStringAsFixed(2)} m/min'),
              _reportSummaryRow('Avg Variance', avgVariance.toStringAsFixed(3)),
              _reportSummaryRow('ZUPT Active',  '${zuptRate.toStringAsFixed(0)}% of time'),
              const Divider(height: 20),

              // Verdict
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: verdictColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: verdictColor, width: 1),
                ),
                child: Text(verdict,
                    style: TextStyle(
                        color: verdictColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // Threshold hint
              if (maxDrift >= 3.0) ...[
                Text(
                  'Avg variance while "stationary": ${avgVariance.toStringAsFixed(3)}\n'
                  'Current STILL_THRESHOLD: 0.5\n'
                  'Suggested STILL_THRESHOLD: ${(avgVariance * 1.5).toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
              ],

              // Drift over time table
              const Text('Drift over Time:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(0.8),
                },
                children: tableRows,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  /// Compact table cell for the static test report.
  Widget _stCell(String text, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black,
          ),
        ),
      );

  void _toggleBlackout() {
    setState(() {
      _gnssActive = !_gnssActive;

      if (!_gnssActive) {
        // ── Entering DR mode ────────────────────────────────────────────────
        _drStartPosition = _displayedPosition;
        _drStartTime     = DateTime.now();

        // Seed raw HW position at last known GNSS fix
        _rawHwPosition = _displayedPosition;
        _rawHwTrajectory.clear();
        if (_rawHwPosition != null) _rawHwTrajectory.add(_rawHwPosition!);

        // Seed DR trajectory — MUST clear first so previous sessions don't bleed in
        _drTrajectory.clear();
        if (_displayedPosition != null) _drTrajectory.add(_displayedPosition!);

        // Start 5 Hz raw hardware integration
        _rawHwTimer?.cancel();
        _rawHwTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
          if (!_gnssActive) _updateRawHardwarePosition();
        });
      } else {
        // ── Restoring GNSS ──────────────────────────────────────────────────
        _rawHwTimer?.cancel();
        _rawHwTimer = null;
        _backendDebugInfo = '';
        _simulateWalking = false; // ensure simulation turns off

        // Compute report before clearing raw data
        if (_drStartPosition != null &&
            (_drTrajectory.isNotEmpty || _rawHwTrajectory.isNotEmpty)) {
          final report = _computeReport();
          // Show dialog after frame settles
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showComparisonReport(report);
          });
        }

        // Clear raw HW trajectory (user confirmed this is desired)
        _rawHwTrajectory.clear();
        _rawHwPosition   = null;
        _drStartPosition = null;
        _drStartTime     = null;
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _dataSendTimer?.cancel();
    _reconnectTimer?.cancel();
    _rawHwTimer?.cancel();
    _staticTestTimer?.cancel();
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
                    // Red line for AI-corrected DR path
                    Polyline(
                      points: _drTrajectory,
                      strokeWidth: 4.0,
                      color: Colors.red,
                    ),
                    // Orange dotted line for raw hardware path (no correction)
                    Polyline(
                      points: _rawHwTrajectory,
                      strokeWidth: 3.0,
                      color: Colors.orange,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Destination Marker with label
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 100,
                        height: 60,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _displayedPosition != null
                                  ? '${_calculateDistance(_displayedPosition!, _destination!).toStringAsFixed(0)}m (straight line)'
                                  : 'Destination',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.location_on, color: Colors.green, size: 32),
                          ],
                        ),
                      ),
                    // Current Position Marker
                    if (_displayedPosition != null)
                      Marker(
                        point: _displayedPosition!,
                        width: 40,
                        height: 40,
                        child: Transform.rotate(
                          angle: _displayedHeadingDeg * (math.pi / 180),
                          child: Icon(
                            Icons.navigation,
                            color: _gnssActive ? Colors.blue : Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                    // Orange ghost arrow for raw hardware position (DR mode only)
                    if (!_gnssActive && _rawHwPosition != null)
                      Marker(
                        point: _rawHwPosition!,
                        width: 28,
                        height: 28,
                        child: Transform.rotate(
                          angle: _rawHwHeadingDeg * (math.pi / 180),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.orange,
                            size: 22,
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

          // ── Simulate Walking button row ───────────────────────────────────
          if (!_gnssActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _simulateWalking = !_simulateWalking;
                    });
                  },
                  icon: Icon(
                    _simulateWalking ? Icons.directions_walk : Icons.man,
                    color: _simulateWalking ? Colors.white : Colors.black87,
                  ),
                  label: Text(
                    _simulateWalking ? 'Stop Simulated Walking' : 'Simulate Walking (points forward)',
                    style: TextStyle(
                      color: _simulateWalking ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _simulateWalking ? Colors.orange.shade800 : Colors.orange.shade100,
                  ),
                ),
              ),
            ),

          // ── Static Test button row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: _staticTestActive
                  ? ElevatedButton.icon(
                      onPressed: () => _stopStaticTest(),
                      icon: const Icon(Icons.stop_circle, color: Colors.white),
                      label: Text(
                        '⏱ ${_staticTestStart != null ? DateTime.now().difference(_staticTestStart!).inSeconds : 0}s | '
                        'Drift: ${_staticTestCurrentDrift.toStringAsFixed(2)} m | '
                        'Max: ${_staticTestMaxDrift.toStringAsFixed(2)} m  —  TAP TO STOP',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startStaticTest,
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Static Accuracy Test (60s)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                      ),
                    ),
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
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    // Live static test row
                    if (_staticTestActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          border: Border.all(color: Colors.purple.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔬 STATIC TEST RUNNING',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                  fontSize: 12),
                            ),
                            Text(
                              'Current Drift: ${_staticTestCurrentDrift.toStringAsFixed(3)} m  |  '
                              'Max: ${_staticTestMaxDrift.toStringAsFixed(3)} m',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                            Text(
                              'Variance: ${_staticTestCurrentVariance.toStringAsFixed(3)}  |  '
                              '${_staticTestZupt ? '🔴 ZUPT (still)' : '🟢 Moving'}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    if (_displayedPosition != null)
                      _buildInfoRow(
                        'Display Lat/Lon:',
                        '${_displayedPosition!.latitude.toStringAsFixed(6)}, ${_displayedPosition!.longitude.toStringAsFixed(6)}',
                        _gnssActive ? Colors.blue : Colors.red,
                      ),
                    _buildInfoRow(
                        'Heading (DR):',
                        '${_displayedHeadingDeg.toStringAsFixed(1)}°',
                        Colors.black,
                      ),
                    // Raw HW heading — only meaningful in DR mode
                    if (!_gnssActive)
                      _buildInfoRow(
                        'Heading (Raw HW):',
                        '${_rawHwHeadingDeg.toStringAsFixed(1)}°',
                        Colors.orange.shade800,
                      ),
                    const Divider(),
                    const Text('Live Sensor Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildSensorRow('Accel', _accelerometerValues),
                    _buildSensorRow('Gyro', _gyroscopeValues),
                    _buildSensorRow('Mag', _magnetometerValues),
                    const Divider(),
                    const Text('Map Legend:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _buildLegendItem(Colors.blue,   'GNSS path (real GPS)'),
                    _buildLegendItem(Colors.red,    'AI-corrected DR path'),
                    _buildLegendItem(Colors.orange, 'Raw hardware path (no correction)'),
                    _buildLegendItem(Colors.green,  'Route to destination'),
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

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
