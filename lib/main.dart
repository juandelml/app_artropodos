import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'servicios/api_service.dart';
import 'lienzo_deteccion.dart';
import 'pantalla_historial.dart';
import 'pantalla_mapa.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clasificador de Artrópodos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  File? _imagenSeleccionada;
  bool _cargando = false;
  Map<String, dynamic>? _resultados;
  
  // Variables para guardar el tamaño real de la foto
  double? _imgAncho;
  double? _imgAlto;
  
  // Control de visibilidad de las cajas
  Set<int> _indicesVisibles = {0};
  
  // Guardar estado del uso de GPS
  bool _incluirUbicacion = false;

  final ImagePicker _picker = ImagePicker();

  Future<Position?> _obtenerUbicacion() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Verifica si los servicios de ubicación están habilitados.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Los servicios de ubicación no están habilitados.
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 10),
          onTimeout: () => LocationPermission.denied,
        );
        if (permission == LocationPermission.denied) {
          // Los permisos son denegados.
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Los permisos son denegados permanentemente.
        return null;
      } 

      // Cuando tenemos permisos, obtenemos la ubicación con timeout
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 15),
        );
      } on TimeoutException {
        print("Timeout al obtener ubicación");
        return null;
      }
    } catch (e) {
      print("Error al obtener ubicación: $e");
      return null;
    }
  }

  // Función para capturar la imagen
  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    
    if (foto != null) {
      try {
        // Leemos los píxeles reales de la imagen de forma asincrónica
        final bytes = await foto.readAsBytes();
        
        // Decodificamos la imagen en un thread separado para no bloquear la UI
        final image = await decodeImageFromList(bytes).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout al procesar la imagen');
          },
        );

        if (mounted) {
          setState(() {
            _imagenSeleccionada = File(foto.path);
            _imgAncho = image.width.toDouble();
            _imgAlto = image.height.toDouble();
            _resultados = null;
            _indicesVisibles.clear(); // Limpiamos las selecciones
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar imagen: $e')),
          );
        }
      }
    }
  }

  // Función para enviar la imagen a Django
  Future<void> _analizarImagen() async {
    if (_imagenSeleccionada == null) return;

    setState(() {
      _cargando = true;
    });

    try {
      print('Iniciando análisis de imagen...');
      
      // Obtenemos la ubicación SOLO si el usuario lo marcó
      Position? posicionLatLng;
      if (_incluirUbicacion) {
        print('Obteniendo ubicación...');
        posicionLatLng = await _obtenerUbicacion();
        print('Ubicación obtenida: $posicionLatLng');
      }

      print('Enviando imagen al servidor...');
      final respuesta = await ApiService.clasificarInsecto(
        _imagenSeleccionada!.path,
        latitud: posicionLatLng?.latitude,
        longitud: posicionLatLng?.longitude,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Timeout: El servidor tardó demasiado en responder (>120s)');
        },
      );

      print('Respuesta recibida: ${respuesta?.keys}');

      if (mounted) {
        setState(() {
          _resultados = respuesta;
          _cargando = false;
          _indicesVisibles.clear();
          // Mostramos todas las cajas por defecto
          if (respuesta != null && respuesta['exito'] == true && respuesta['detecciones'] != null) {
            for (int i = 0; i < (respuesta['detecciones'] as List).length; i++) {
              _indicesVisibles.add(i);
            }
          }
        });
        
        if (respuesta == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No se recibió respuesta del servidor')),
          );
        }
      }
    } catch (e) {
      print('Error al analizar: $e');
      if (mounted) {
        setState(() {
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Artrópodos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Ver Mapa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PantallaMapa()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver Historial',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PantallaHistorial()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. El Lienzo con la imagen y la caja (o la imagen devuelta por el servidor)
              if (_imagenSeleccionada != null && _imgAncho != null && _imgAlto != null)
                LienzoDeteccion(
                  imagen: _imagenSeleccionada!,
                  detecciones: _resultados != null ? _resultados!['detecciones'] : null,
                  indicesVisibles: _indicesVisibles, // Le dice al lienzo cuáles dibujar
                  imgAncho: _imgAncho!,
                  imgAlto: _imgAlto!,
                )
              else
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('Toma una foto para comenzar el análisis.'),
                ),

              // 2. Botón flotante (Chip) para activar/desactivar la caja
              if (_resultados != null && _resultados!['exito'] == true && _resultados!['detecciones'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: List<Widget>.generate(
                      (_resultados!['detecciones'] as List).length,
                      (int index) {
                        final det = _resultados!['detecciones'][index];
                        return FilterChip(
                          label: Text('${det['clase']} (${det['confianza']})'),
                          selected: _indicesVisibles.contains(index),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _indicesVisibles.add(index);
                              } else {
                                _indicesVisibles.remove(index);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              
              const SizedBox(height: 10),
              
              // 3. Switch opcional para ubicación
              if (_imagenSeleccionada != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: SwitchListTile(
                    title: const Text('Incluir mi ubicación en el registro'),
                    subtitle: const Text('Útil si capturaste el insecto en este mismo lugar'),
                    value: _incluirUbicacion,
                    onChanged: _cargando 
                        ? null 
                        : (bool value) {
                            setState(() {
                              _incluirUbicacion = value;
                            });
                          },
                  ),
                ),
              
              const SizedBox(height: 10),
              
              // 4. Botones principales
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _cargando ? null : _tomarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar Foto'),
                  ),
                  const SizedBox(width: 15),
                  if (_imagenSeleccionada != null)
                    ElevatedButton.icon(
                      onPressed: _cargando ? null : _analizarImagen,
                      icon: const Icon(Icons.search),
                      label: const Text('Analizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Resultados de texto
              if (_cargando)
                const CircularProgressIndicator()
              else if (_resultados != null && _resultados!['exito'] == true)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _resultados!['detecciones'] != null && (_resultados!['detecciones'] as List).isNotEmpty
                      ? Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 50),
                            const SizedBox(height: 8),
                            if (_resultados!['tiempo_servidor_ms'] != null)
                              Text(
                                'Tiempo: ${_resultados!['tiempo_servidor_ms'] is double ? _resultados!['tiempo_servidor_ms'].toStringAsFixed(2) : _resultados!['tiempo_servidor_ms']} ms',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Detecciones encontradas: ${(_resultados!['detecciones'] as List).length}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            for (var det in (_resultados!['detecciones'] as List))
                              Column(
                                children: [
                                  Text(
                                    'Clase: ${det['clase']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Confianza: ${det['confianza']}',
                                    style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                                  ),
                                  const SizedBox(height: 12),
                                ]
                              )
                          ],
                        )
                      : const Column(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
                            SizedBox(height: 8),
                            Text(
                              'No se detectaron artrópodos.',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}