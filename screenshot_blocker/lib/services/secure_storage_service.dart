import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Los 4 campos sensibles
  static const _keyToken        = 'user_auth_token';
  static const _keyPin          = 'user_pin';
  static const _keyNumTarjeta   = 'numero_tarjeta';
  static const _keyCurp         = 'curp_usuario';

  // ── GUARDAR ──────────────────────────────────
  Future<void> guardarDatos() async {
    await _storage.write(key: _keyToken,      value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc123');
    await _storage.write(key: _keyPin,        value: '7291');
    await _storage.write(key: _keyNumTarjeta, value: '4532-1234-5678-9012');
    await _storage.write(key: _keyCurp,       value: 'HEGJ990512HCSRNV04');
    print('✅ Datos sensibles guardados');
  }

  // ── LEER TODOS ───────────────────────────────
  Future<Map<String, String?>> leerDatos() async {
    return {
      'Token':          await _storage.read(key: _keyToken),
      'PIN':            await _storage.read(key: _keyPin),
      'Num. Tarjeta':   await _storage.read(key: _keyNumTarjeta),
      'CURP':           await _storage.read(key: _keyCurp),
    };
  }

  // ── BORRAR TODO (se activa con la notificación) ──
  Future<void> deleteAllSensitiveData() async {
    await _storage.deleteAll();
    print('🗑️ Datos sensibles eliminados remotamente');
  }

  // Verificar si hay datos
  Future<bool> hayDatos() async {
    final token = await _storage.read(key: _keyToken);
    return token != null;
  }
}