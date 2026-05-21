// lib/screens/gps_check_screen.dart
import 'package:flutter/material.dart';
import 'package:loginoutscreen/services/fake_gps_detector.dart';

class GPSCheckScreen extends StatefulWidget {
  final Widget nextScreen;
  const GPSCheckScreen({super.key, required this.nextScreen});

  @override
  State<GPSCheckScreen> createState() => _GPSCheckScreenState();
}

class _GPSCheckScreenState extends State<GPSCheckScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isChecking = true;
  GPSStatus? _result;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar verificación al arrancar la pantalla
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() {
      _isChecking = true;
      _result = null;
    });

    // Pequeño delay visual para que el usuario vea la pantalla de carga
    await Future.delayed(const Duration(milliseconds: 800));

    final status = await FakeGPSDetector().checkOnce();

    if (!mounted) return;

    setState(() {
      _isChecking = false;
      _result = status;
    });

    if (status == GPSStatus.real) {
      _showRealGPSDialog();
    } else if (status == GPSStatus.fake) {
      _showFakeGPSDialog();
    } else {
      // No se pudo obtener GPS (permiso denegado, sin servicio, etc.)
      _showUnknownDialog();
    }
  }

  void _showRealGPSDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GPSDialog(
        icon: Icons.verified_rounded,
        iconColor: const Color(0xFFFF6B35),
        title: 'GPS Verificado',
        message:
        'Ubicación real detectada. Puedes continuar sin restricciones.',
        buttonLabel: 'Continuar',
        buttonColor: const Color(0xFFFF6B35),
        onPressed: () {
          Navigator.of(context).pop();
          _goToNext();
        },
      ),
    );
  }

  void _showFakeGPSDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GPSDialog(
        icon: Icons.gps_off_rounded,
        iconColor: const Color(0xFFFF6B35),
        title: 'GPS Falso Detectado',
        message:
        'Se detectó una aplicación de GPS falso activa. Desactívala para poder continuar.',
        buttonLabel: 'Reintentar',
        buttonColor: const Color(0xFFFF6B35),
        onPressed: () {
          Navigator.of(context).pop();
          _runCheck();
        },
      ),
    );
  }

  void _showUnknownDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GPSDialog(
        icon: Icons.location_off_rounded,
        iconColor: const Color(0xFFFF6B35),
        title: 'GPS No Disponible',
        message:
        'No se pudo verificar tu ubicación. Asegúrate de habilitar el GPS y otorgar permisos.',
        buttonLabel: 'Reintentar',
        buttonColor: const Color(0xFFFF6B35),
        onPressed: () {
          Navigator.of(context).pop();
          _runCheck();
        },
      ),
    );
  }

  void _goToNext() {
    // Iniciar monitoreo continuo en background
    FakeGPSDetector().startMonitoring();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono animado
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _isChecking
                          ? Icons.gps_not_fixed_rounded
                          : (_result == GPSStatus.real
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_off_rounded),
                      size: 48,
                      color: _isChecking
                          ? Colors.white70
                          : const Color(0xFFFF6B35),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  _isChecking ? 'Verificando GPS...' : 'Verificación completa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    _isChecking
                        ? 'Comprobando la autenticidad de tu ubicación'
                        : (_result == GPSStatus.real
                        ? 'Ubicación verificada correctamente'
                        : 'Se detectó una anomalía en el GPS'),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                if (_isChecking) ...[
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: const Color(0xFFFF6B35).withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _GPSDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _GPSDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: buttonColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 2,
                  width: 40,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [buttonColor, buttonColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -40,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                shape: BoxShape.circle,
                border: Border.all(color: buttonColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: buttonColor,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}