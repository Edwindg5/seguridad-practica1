import 'package:flutter/services.dart';

class SecurityService {
  static const _channel = MethodChannel('com.example.screenshot_blocker/security');

  static Future<void> setSecure(bool enable) async {
    try {
      await _channel.invokeMethod('setSecure', {'enable': enable});
    } on PlatformException catch (e) {
      print("Error configurando FLAG_SECURE: '${e.message}'.");
    }
  }
}
