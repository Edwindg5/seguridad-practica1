// lib/services/mock_location_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_mock_location_detector/flutter_mock_location_detector.dart';

class MockLocationService {
  static final MockLocationService _instance = MockLocationService._internal();
  factory MockLocationService() => _instance;
  MockLocationService._internal();

  bool _isMonitoring = false;
  bool _isMockLocationEnabled = false;

  // Método para iniciar la detección SIN mostrar alertas
  Future<void> startDetectionWithoutAlerts() async {
    if (_isMonitoring) return;

    try {
      // Inicializar el detector
      await FlutterMockLocationDetector.init();

      // Escuchar cambios en la ubicación falsa sin mostrar alertas
      FlutterMockLocationDetector.listenOnLocationMockChange((isMock) {
        _isMockLocationEnabled = isMock;
        debugPrint('Mock location detection: $_isMockLocationEnabled');

        // Aquí puedes hacer acciones internas sin mostrar alertas
        // Por ejemplo: guardar el estado, enviar a un servidor, etc.
        _handleMockLocationChange(isMock);
      });

      _isMonitoring = true;
      debugPrint('Mock location detection started (silent mode)');
    } catch (e) {
      debugPrint('Error starting mock location detection: $e');
    }
  }

  // Método para detener la detección
  Future<void> stopDetection() async {
    if (!_isMonitoring) return;

    try {
      await FlutterMockLocationDetector.dispose();
      _isMonitoring = false;
      debugPrint('Mock location detection stopped');
    } catch (e) {
      debugPrint('Error stopping detection: $e');
    }
  }

  // Método interno para manejar cambios sin mostrar alertas
  void _handleMockLocationChange(bool isMock) {
    // Aquí puedes implementar tu lógica personalizada
    // Por ejemplo:

    if (isMock) {
      debugPrint('⚠️ Fake GPS detected - No alert shown');
      // Puedes bloquear funcionalidades internamente
      // o guardar este estado para usarlo más tarde
    } else {
      debugPrint('✅ Real GPS detected');
    }
  }

  // Método para obtener el estado actual
  bool isMockLocationEnabled() {
    return _isMockLocationEnabled;
  }

  // Método para verificar manualmente (si es necesario)
  Future<bool> checkCurrentStatus() async {
    try {
      final isMock = await FlutterMockLocationDetector.isMockLocationEnabled();
      _isMockLocationEnabled = isMock;
      return isMock;
    } catch (e) {
      debugPrint('Error checking mock location status: $e');
      return false;
    }
  }
}