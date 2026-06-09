import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Usamos la IP que te dio tu Mac
  static const String _baseUrl = 'http://10.13.4.12:8000/api/clasificar/';
  static const String _historialUrl = 'http://10.13.4.12:8000/api/historial/';

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
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      
      File archivoFoto = File(rutaImagen);
      if (!await archivoFoto.exists()) return null;
      
      request.files.add(
        await http.MultipartFile.fromPath('imagen', archivoFoto.path)
      );

      // Agregamos las coordenadas GPS si se obtuvieron
      if (latitud != null && longitud != null) {
        request.fields['latitud'] = latitud.toString();
        request.fields['longitud'] = longitud.toString();
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        print("Error en servidor: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error de conexión: $e");
      return null;
    }
  }
}