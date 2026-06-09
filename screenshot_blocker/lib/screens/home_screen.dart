import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/fcm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String?> _datos = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();

    // Escuchar cuando FCM borra los datos y recargar automáticamente
    FCMService().onDataWiped = () {
      if (mounted) {
        _cargarDatos();
      }
    };
  }

  @override
  void dispose() {
    FCMService().onDataWiped = null;
    super.dispose();
  }

  Future<void> _inicializar() async {
    final hayDatos = await SecureStorageService().hayDatos();
    if (!hayDatos) {
      await SecureStorageService().guardarDatos();
    }
    await _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await SecureStorageService().leerDatos();
    if (mounted) {
      setState(() {
        _datos = datos;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Datos Seguros', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: Colors.green),
            onPressed: () async {
              await SecureStorageService().guardarDatos();
              await _cargarDatos();
            },
            tooltip: 'Restaurar datos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
            onPressed: _cargarDatos,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔐 Almacenamiento Seguro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estos datos se borran remotamente al recibir\nla notificación con la palabra clave.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ..._datos.entries.map((e) => _buildCard(e.key, e.value)),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(String campo, String? valor) {
    final vacio = valor == null || valor.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vacio
              ? Colors.red.withOpacity(0.4)
              : const Color(0xFFFF6B35).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            vacio ? Icons.delete_forever : Icons.lock,
            color: vacio ? Colors.red : const Color(0xFFFF6B35),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  vacio ? '⚠️ BORRADO REMOTAMENTE' : valor!,
                  style: TextStyle(
                    color: vacio ? Colors.red : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
