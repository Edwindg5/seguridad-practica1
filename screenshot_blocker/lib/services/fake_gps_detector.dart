// lib/services/fake_gps_detector.dart
import 'dart:async';
import 'dart:math';
import 'package:location/location.dart';

enum GPSStatus {
  unknown,
  checking,
  real,
  fake,
}

class FakeGPSDetector {
  static final FakeGPSDetector _instance = FakeGPSDetector._internal();
  factory FakeGPSDetector() => _instance;
  FakeGPSDetector._internal();

  final Location _location = Location();
  bool _isMonitoring = false;
  GPSStatus _gpsStatus = GPSStatus.unknown;
  Timer? _validationTimer;
  StreamSubscription? _locationSubscription;

  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastLocationTime;
  int _suspiciousJumps = 0;

  // Callback para notificar cambios de estado
  Function(GPSStatus)? onGPSStatusChanged;

  /// Verifica GPS una sola vez al inicio y retorna el estado
  Future<GPSStatus> checkOnce() async {
    _gpsStatus = GPSStatus.checking;

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return GPSStatus.unknown;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return GPSStatus.unknown;
        }
      }

      final LocationData location = await _location.getLocation();
      _gpsStatus = _analyzeLocation(location);
      return _gpsStatus;
    } catch (e) {
      print('❌ Error checking GPS: $e');
      return GPSStatus.unknown;
    }
  }

  /// Inicia monitoreo continuo en segundo plano
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      _locationSubscription =
          _location.onLocationChanged.listen((LocationData currentLocation) {
            final newStatus = _analyzeLocation(currentLocation);
            if (newStatus != _gpsStatus) {
              _gpsStatus = newStatus;
              onGPSStatusChanged?.call(_gpsStatus);
            }
          });

      _isMonitoring = true;
      print('✅ GPS monitoring started');

      _validationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        try {
          final LocationData location = await _location.getLocation();
          final newStatus = _analyzeLocation(location);
          if (newStatus != _gpsStatus) {
            _gpsStatus = newStatus;
            onGPSStatusChanged?.call(_gpsStatus);
          }
        } catch (e) {
          print('Periodic check error: $e');
        }
      });
    } catch (e) {
      print('❌ Error starting monitoring: $e');
    }
  }

  GPSStatus _analyzeLocation(LocationData location) {
    if (location.latitude == null || location.longitude == null) {
      return GPSStatus.unknown;
    }

    // 1. Mock provider (Android flag directo)
    bool isFromMockProvider = location.isMock ?? false;

    // 2. Precisión sospechosamente perfecta (< 1 metro)
    bool hasSuspiciousAccuracy =
        location.accuracy != null && location.accuracy! < 1.0;

    // 3. Velocidad físicamente imposible entre puntos
    bool hasImpossibleSpeed = false;
    if (_lastLatitude != null &&
        _lastLongitude != null &&
        _lastLocationTime != null) {
      double distance = _calculateDistance(
        _lastLatitude!,
        _lastLongitude!,
        location.latitude!,
        location.longitude!,
      );
      double timeDiff =
      DateTime.now().difference(_lastLocationTime!).inSeconds.toDouble();
      if (timeDiff > 0) {
        double speed = distance / timeDiff;
        if (speed > 500) {
          hasImpossibleSpeed = true;
          _suspiciousJumps++;
        }
      }
    }

    _lastLatitude = location.latitude;
    _lastLongitude = location.longitude;
    _lastLocationTime = DateTime.now();

    bool isFake =
        isFromMockProvider || hasSuspiciousAccuracy || (_suspiciousJumps >= 3);

    if (isFake) {
      print('⚠️ FAKE GPS DETECTED');
      print('   - Mock provider: $isFromMockProvider');
      print('   - Suspicious accuracy: $hasSuspiciousAccuracy');
      print('   - Impossible jumps: $_suspiciousJumps');
      return GPSStatus.fake;
    } else {
      if (_gpsStatus == GPSStatus.fake) {
        _suspiciousJumps = 0;
      }
      print('✅ Real GPS detected');
      return GPSStatus.real;
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  void stopMonitoring() {
    _isMonitoring = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _validationTimer?.cancel();
    _validationTimer = null;
    print('🛑 GPS monitoring stopped');
  }

  GPSStatus get status => _gpsStatus;
  bool get isFakeDetected => _gpsStatus == GPSStatus.fake;
}