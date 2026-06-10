import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/login_screen.dart';

class InactivityService {
  static final InactivityService _instance = InactivityService._internal();
  factory InactivityService() => _instance;
  InactivityService._internal();

  // 5 segundos para pruebas (cambiar a 300 para producción)
  static const int timeoutSeconds = 5;

  Timer? _timer;
  bool _isActive = false;

  void start(BuildContext context) {
    _isActive = true;
    _resetTimer();
  }

  void stop() {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
  }

  void resetTimer() {
    if (!_isActive) return;
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: timeoutSeconds), _onTimeout);
  }

  void _onTimeout() {
    if (!_isActive) return;
    _isActive = false;
    _timer = null;

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );

    // Mostrar SnackBar de sesión expirada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newCtx = navigatorKey.currentContext;
      if (newCtx == null) return;
      ScaffoldMessenger.of(newCtx).showSnackBar(
        const SnackBar(
          content: Text('⏱️ Sesión cerrada por inactividad'),
          backgroundColor: Color(0xFFFF6B35),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }
}
