import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // IP
  static const String baseUrlHost = 'http://10.13.100.97:8000';
  static const String _baseUrl = '$baseUrlHost/api/clasificar/';
  static const String _historialUrl = '$baseUrlHost/api/historial/';

  // Nueva función para obtener el historial
  static Future<List<dynamic>?> obtenerHistorial() async {
    try {
      var response = await http.get(Uri.parse(_historialUrl));
      if (response.statusCode == 200) {
        // Asume que devolvemos un arreglo de registros o la clave de diccionario
        var body = jsonDecode(response.body);
        return body is List ? body : body['resultados']; 
      } else {
        print("Error en servidor al obtener historial: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error de conexión al obtener historial: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> clasificarInsecto(String rutaImagen, {double? latitud, double? longitud}) async {
    try {
      print('[API] Iniciando clasificación de: $rutaImagen');
      
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      File archivoFoto = File(rutaImagen);
      if (!await archivoFoto.exists()) {
        print("[API] ERROR: Archivo no existe: $rutaImagen");
        return null;
      }
      
      int fileSizeBytes = await archivoFoto.length();
      print("[API] Tamaño del archivo: ${(fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB");
      
      request.files.add(
        await http.MultipartFile.fromPath('imagen', archivoFoto.path)
      );

      // Agregamos las coordenadas GPS si se obtuvieron
      if (latitud != null && longitud != null) {
        request.fields['latitud'] = latitud.toString();
        request.fields['longitud'] = longitud.toString();
        print("[API] Incluidas coordenadas GPS: $latitud, $longitud");
      }

      print("[API] Enviando solicitud a: $_baseUrl");
      print("[API] Esperando respuesta (timeout: 120s)...");
      
      // Enviamos con timeout
      var response = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Timeout al enviar la imagen (120s)');
        },
      );

      print("[API] Respuesta recibida con status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout al recibir respuesta del servidor (30s)');
          },
        );
        
        print("[API] Tamaño de respuesta: ${responseBody.length} bytes");
        
        var decoded = jsonDecode(responseBody);
        print("[API] Análisis completado exitosamente");
        return decoded;
      } else {
        print("[API] ERROR: Status ${response.statusCode}");
        var errorBody = await response.stream.bytesToString();
        print("[API] Respuesta de error: $errorBody");
        return null;
      }
    } catch (e) {
      print("[API] ERROR CRÍTICO: $e");
      return null;
    }
  }
}