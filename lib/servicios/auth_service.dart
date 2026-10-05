import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/usuario_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _prefTokenKey = 'auth_token';
  static const String _prefUserDataKey = 'user_data';

  // Notificador reactivo para que la app sepa inmediatamente cuándo cambia el usuario
  static final ValueNotifier<UsuarioModel?> usuarioActualNotifier =
      ValueNotifier<UsuarioModel?>(null);

  /// Inicializa la sesión cargando el usuario guardado en caché si existe
  static Future<UsuarioModel?> inicializarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefTokenKey);
    final userJsonStr = prefs.getString(_prefUserDataKey);

    if (token != null && userJsonStr != null) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        final usuario = UsuarioModel.fromJson(userMap);
        usuarioActualNotifier.value = usuario;
        return usuario;
      } catch (e) {
        debugPrint('Error al deserializar usuario en caché: $e');
      }
    }
    usuarioActualNotifier.value = null;
    return null;
  }

  /// Retorna el token de autenticación guardado
  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefTokenKey);
  }

  /// Retorna true si hay un token guardado
  static Future<bool> estaAutenticado() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }

  /// Inicia sesión únicamente con correo electrónico y contraseña
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrlHost}/api/auth/login/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['exito'] == true) {
        final token = data['token'] as String;
        final usuario = UsuarioModel.fromJson(data['usuario']);

        // Guardar sesión en almacenamiento local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefTokenKey, token);
        await prefs.setString(_prefUserDataKey, jsonEncode(usuario.toJson()));

        usuarioActualNotifier.value = usuario;

        return {
          'exito': true,
          'mensaje': data['mensaje'] ?? 'Bienvenido',
          'usuario': usuario,
          'token': token,
        };
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Credenciales incorrectas.',
        };
      }
    } catch (e) {
      return {
        'exito': false,
        'error': 'Error de conexión con el servidor: $e',
      };
    }
  }

  /// Registra un nuevo usuario en el sistema
  static Future<Map<String, dynamic>> signup({
    required String nombre,
    required String apellidos,
    required String username,
    required String email,
    required String password,
    String institucion = '',
    String rol = 'observador',
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrlHost}/api/auth/signup/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre.trim(),
          'apellidos': apellidos.trim(),
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'institucion': institucion.trim(),
          'rol': rol,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['exito'] == true) {
        final token = data['token'] as String;
        final usuario = UsuarioModel.fromJson(data['usuario']);

        // Guardar sesión automáticamente al registrarse
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefTokenKey, token);
        await prefs.setString(_prefUserDataKey, jsonEncode(usuario.toJson()));

        usuarioActualNotifier.value = usuario;

        return {
          'exito': true,
          'mensaje': data['mensaje'] ?? 'Registro completado',
          'usuario': usuario,
          'token': token,
        };
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'No se pudo completar el registro.',
        };
      }
    } catch (e) {
      return {
        'exito': false,
        'error': 'Error de conexión con el servidor: $e',
      };
    }
  }

  /// Cierra la sesión en el servidor y borra la caché local
  static Future<void> logout() async {
    try {
      final token = await obtenerToken();
      if (token != null) {
        final url = Uri.parse('${ApiService.baseUrlHost}/api/auth/logout/');
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('Error silencioso al notificar logout al servidor: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefTokenKey);
      await prefs.remove(_prefUserDataKey);
      usuarioActualNotifier.value = null;
    }
  }
}
