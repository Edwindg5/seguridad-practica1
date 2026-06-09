import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'secure_storage_service.dart';

// Handler background — DEBE ser función top-level (fuera de clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final action = message.data['action'] ?? '';
  if (action == 'WIPE_SECURE_DATA') {
    await SecureStorageService().deleteAllSensitiveData();
    print('🗑️ [BACKGROUND] Datos borrados por notificación remota');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();
  Function()? onDataWiped;

  // ← PALABRA CLAVE SECRETA
  static const _actionKey = 'WIPE_SECURE_DATA';

  Future<void> initialize() async {
    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Pedir permisos
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Configurar notificaciones locales
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Obtener y mostrar el token del dispositivo
    final token = await _messaging.getToken();
    print('📱 FCM Token: $token');

    // Escuchar en FOREGROUND
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Cuando app estaba en background y usuario toca la notif
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final action = message.data['action'] ?? '';
    print('📩 Notificación recibida | action: "$action"');

    if (action == _actionKey) {
      // ⚠️ Borrar datos — silencioso, sin mostrar notificación
      SecureStorageService().deleteAllSensitiveData().then((_) {
        onDataWiped?.call();
      });
      print('🗑️ [FOREGROUND] Datos borrados por notificación remota');
      return;
    }

    // Cualquier otra notificación se muestra normalmente
    _mostrarNotificacion(
      titulo: message.notification?.title ?? 'Notificación',
      cuerpo: message.notification?.body ?? '',
    );
  }

  Future<void> _mostrarNotificacion({
    required String titulo,
    required String cuerpo,
  }) async {
    await _localNotif.show(
      0,
      titulo,
      cuerpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general_channel',
          'General',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<String?> getToken() => _messaging.getToken();
}