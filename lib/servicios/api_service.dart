import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ==========================================
  // CONFIGURACIÓN DE CONEXIÓN AL BACKEND
  // ==========================================
  // Opción 1: Emulador de Android (10.0.2.2 redirige automáticamente al localhost de tu Mac)
  static const String baseUrlHost = 'http://10.0.2.2:8000';

  // Opción 2: Celular físico (debe estar conectado a la misma red Wi-Fi que tu Mac)
  // static const String baseUrlHost = 'http://10.13.100.150:8000';
  // ==========================================

  static const String _baseUrl = '$baseUrlHost/api/clasificar/';
  static const String _historialUrl = '$baseUrlHost/api/historial/';

  /// Obtiene el token de autenticación almacenado
  static Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Función para obtener el historial de avistamientos
  static Future<List<dynamic>?> obtenerHistorial({bool soloMios = false}) async {
    try {
      final token = await _obtenerToken();
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }

      final url = soloMios ? '$_historialUrl?solo_mios=true' : _historialUrl;
      var response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        var body = jsonDecode(response.body);
        return body is List ? body : body['resultados'];
      } else {
        debugPrint("Error en servidor al obtener historial: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error de conexión al obtener historial: $e");
      return null;
    }
  }

  /// Función para clasificar una foto de artrópodo y vincularla con el usuario
  static Future<Map<String, dynamic>?> clasificarInsecto(
    String rutaImagen, {
    double? latitud,
    double? longitud,
  }) async {
    try {
      debugPrint('[API] Iniciando clasificación de: $rutaImagen');

      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      // Adjuntar Token en headers si el usuario está autenticado
      final token = await _obtenerToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Token $token';
      }

      File archivoFoto = File(rutaImagen);
      if (!await archivoFoto.exists()) {
        debugPrint("[API] ERROR: Archivo no existe: $rutaImagen");
        return null;
      }

      int fileSizeBytes = await archivoFoto.length();
      debugPrint("[API] Tamaño del archivo: ${(fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB");

      request.files.add(
        await http.MultipartFile.fromPath('imagen', archivoFoto.path),
      );

      // Coordenadas GPS
      if (latitud != null && longitud != null) {
        request.fields['latitud'] = latitud.toString();
        request.fields['longitud'] = longitud.toString();
        debugPrint("[API] Incluidas coordenadas GPS: $latitud, $longitud");
      }

      debugPrint("[API] Enviando solicitud a: $_baseUrl");
      debugPrint("[API] Esperando respuesta (timeout: 120s)...");

      var response = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Timeout al enviar la imagen (120s)');
        },
      );

      debugPrint("[API] Respuesta recibida con status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout al recibir respuesta del servidor (30s)');
          },
        );

        debugPrint("[API] Tamaño de respuesta: ${responseBody.length} bytes");
        var decoded = jsonDecode(responseBody);
        debugPrint("[API] Análisis completado exitosamente");
        return decoded;
      } else {
        debugPrint("[API] ERROR: Status ${response.statusCode}");
        var errorBody = await response.stream.bytesToString();
        debugPrint("[API] Respuesta de error: $errorBody");
        return null;
      }
    } catch (e) {
      debugPrint("[API] ERROR CRÍTICO: $e");
      return null;
    }
  }

  /// Eliminar un avistamiento del historial (disponible para Admin o creador de la captura)
  static Future<bool> eliminarAvistamiento(String idAvistamiento) async {
    try {
      final token = await _obtenerToken();
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }

      final url = Uri.parse('$_historialUrl$idAvistamiento/');
      final response = await http.delete(url, headers: headers).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        debugPrint('[API] Avistamiento $idAvistamiento eliminado exitosamente');
        return true;
      } else {
        debugPrint('[API] Error al eliminar avistamiento: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[API] Error de red al eliminar avistamiento: $e');
      return false;
    }
  }
}