import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/gps_check_screen.dart';
import 'screens/login_screen.dart';
import 'services/fcm_service.dart';
import 'services/inactivity_service.dart';

// NavigatorKey global para navegación desde servicios
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tarea 1: Bloqueo de capturas (System UI Style)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle());
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Captura CUALQUIER toque en toda la app para resetear el timer de inactividad
      onPointerDown: (_) => InactivityService().resetTimer(),
      onPointerMove: (_) => InactivityService().resetTimer(),
      child: MaterialApp(
        title: 'Security App',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFFF6B35),
          useMaterial3: true,
        ),
        home: const GPSCheckScreen(nextScreen: LoginScreen()),
      ),
    );
  }
}
