import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../servicios/api_service.dart';
import '../servicios/auth_service.dart';
import '../lienzo_deteccion.dart';
import '../pantalla_detalle_deteccion.dart';
import 'dialogo_perfil.dart';

class PantallaCaptura extends StatefulWidget {
  const PantallaCaptura({super.key});

  @override
  State<PantallaCaptura> createState() => _PantallaCapturaState();
}

class _PantallaCapturaState extends State<PantallaCaptura> {
  File? _imagenSeleccionada;
  bool _cargando = false;
  Map<String, dynamic>? _resultados;

  // Variables para guardar el tamaño real de la foto
  double? _imgAncho;
  double? _imgAlto;

  // Control de visibilidad de las cajas
  final Set<int> _indicesVisibles = {0};

  // Guardar estado del uso de GPS
  bool _incluirUbicacion = false;

  final ImagePicker _picker = ImagePicker();

  Future<Position?> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 10),
          onTimeout: () => LocationPermission.denied,
        );
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        return null;
      }
    } catch (e) {
      debugPrint("Error al obtener ubicación: $e");
      return null;
    }
  }

  Future<void> _seleccionarImagen(ImageSource origen) async {
    try {
      final XFile? foto = await _picker.pickImage(source: origen);

      if (foto != null) {
        final bytes = await foto.readAsBytes();
        final image = await decodeImageFromList(bytes).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timeout al procesar la imagen'),
        );

        if (mounted) {
          setState(() {
            _imagenSeleccionada = File(foto.path);
            _imgAncho = image.width.toDouble();
            _imgAlto = image.height.toDouble();
            _resultados = null;
            _indicesVisibles.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _tomarFoto() => _seleccionarImagen(ImageSource.camera);
  Future<void> _seleccionarDeGaleria() => _seleccionarImagen(ImageSource.gallery);

  Future<void> _analizarImagen() async {
    if (_imagenSeleccionada == null) return;

    setState(() => _cargando = true);

    try {
      Position? posicionLatLng;
      if (_incluirUbicacion) {
        posicionLatLng = await _obtenerUbicacion();
      }

      final respuesta = await ApiService.clasificarInsecto(
        _imagenSeleccionada!.path,
        latitud: posicionLatLng?.latitude,
        longitud: posicionLatLng?.longitude,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('Timeout: El servidor tardó más de 120s en responder'),
      );

      if (mounted) {
        if (respuesta == null) {
          setState(() => _cargando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No se recibió respuesta del servidor')),
          );
        } else if (respuesta['exito'] == false ||
            respuesta['detecciones'] == null ||
            (respuesta['detecciones'] as List).isEmpty) {
          setState(() {
            _resultados = respuesta;
            _cargando = false;
          });
          final mensaje = respuesta['mensaje']?.toString() ?? 'No se detectó ningún artrópodo en la imagen.';
          _mostrarDialogoSinDetecciones(mensaje);
        } else {
          // ¡Éxito en la detección!
          final fotoLocal = _imagenSeleccionada;
          final usuarioActual = AuthService.usuarioActualNotifier.value;

          final registro = {
            'id': respuesta['id'],
            'imagen_url': respuesta['imagen_url'],
            'archivo_local': fotoLocal,
            'fecha_hora': respuesta['fecha_hora'] ?? DateTime.now().toIso8601String(),
            'latitud': posicionLatLng?.latitude ?? respuesta['latitud'],
            'longitud': posicionLatLng?.longitude ?? respuesta['longitud'],
            'detecciones': respuesta['detecciones'],
            'usuario': respuesta['usuario'] ?? usuarioActual?.username ?? 'Anónimo',
            'institucion': respuesta['institucion'] ?? usuarioActual?.institucion ?? '',
            'usuario_id': respuesta['usuario_id'] ?? usuarioActual?.id.toString(),
          };

          final count = (respuesta['detecciones'] as List).length;

          // Limpiamos el formulario de captura para evitar reenvíos duplicados
          _limpiarCaptura();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Se detectaron $count artrópodo(s)! Mostrando detalle...'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navegamos directamente a la pantalla de detalle
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaDetalleDeteccion(registro: registro),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _mostrarDialogoSinDetecciones(String mensaje) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Icon(Icons.search_off_rounded, size: 54, color: Colors.orange.shade800),
                const SizedBox(height: 12),
                Text(
                  'No se detectaron artrópodos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nota: Esta fotografía no se guardó en la base de datos ni en el historial. Intenta tomar una nueva foto con mejor iluminación y mayor acercamiento al insecto o arácnido.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _tomarFoto();
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar otra'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _seleccionarDeGaleria();
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _limpiarCaptura() {
    setState(() {
      _imagenSeleccionada = null;
      _resultados = null;
      _imgAncho = null;
      _imgAlto = null;
      _indicesVisibles.clear();
      _incluirUbicacion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Captura'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          if (_imagenSeleccionada != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Limpiar foto actual',
              onPressed: _cargando ? null : _limpiarCaptura,
            ),
          ValueListenableBuilder(
            valueListenable: AuthService.usuarioActualNotifier,
            builder: (context, usuario, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                child: IconButton(
                  tooltip: usuario != null
                      ? '@${usuario.username} (${usuario.esAdmin ? 'Admin' : 'Observador'})'
                      : 'Perfil',
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: (usuario?.esAdmin ?? false)
                        ? Colors.amber.shade200
                        : Colors.green.shade200,
                    child: Text(
                      usuario != null && usuario.nombre.isNotEmpty
                          ? usuario.nombre[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: (usuario?.esAdmin ?? false)
                            ? Colors.amber.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ),
                  onPressed: () => DialogoPerfil.mostrar(context, usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Lienzo con imagen o placeholder
              if (_imagenSeleccionada != null && _imgAncho != null && _imgAlto != null)
                LienzoDeteccion(
                  imagen: _imagenSeleccionada!,
                  detecciones: _resultados != null ? _resultados!['detecciones'] : null,
                  indicesVisibles: _indicesVisibles,
                  imgAncho: _imgAncho!,
                  imgAlto: _imgAlto!,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_a_photo, size: 48, color: Colors.green.shade800),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Toma o sube una fotografía',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nuestros modelos YOLOv8 y MobileNetV3 detectarán y clasificarán automáticamente el orden del artrópodo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Chips para alternar visibilidad de cajas
              if (_resultados != null && _resultados!['exito'] == true && _resultados!['detecciones'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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

              const SizedBox(height: 8),

              // 3. Switch opcional para GPS
              if (_imagenSeleccionada != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: const Text('Incluir ubicación GPS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Guarda la latitud y longitud para el mapa global', style: TextStyle(fontSize: 12)),
                      value: _incluirUbicacion,
                      onChanged: _cargando ? null : (bool value) => setState(() => _incluirUbicacion = value),
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              // 4. Botones de acción principales
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _cargando ? null : _tomarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _cargando ? null : _seleccionarDeGaleria,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),

              if (_imagenSeleccionada != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _analizarImagen,
                    icon: const Icon(Icons.biotech),
                    label: const Text('Analizar Ahora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 5. Resultados
              if (_cargando)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Detectando y clasificando artrópodo...',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                )
              else if (_resultados != null && _resultados!['exito'] == true && _resultados!['detecciones'] != null && (_resultados!['detecciones'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      if (_resultados!['tiempo_servidor_ms'] != null)
                        Text(
                          'Procesado en: ${_resultados!['tiempo_servidor_ms']} ms',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_resultados!['detecciones'] as List).length} artrópodo(s) detectado(s)',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      for (var det in (_resultados!['detecciones'] as List))
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.pest_control, color: Colors.green),
                            title: Text(
                              det['clase']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Confianza: ${det['confianza']}'),
                          ),
                        ),
                    ],
                  ),
                )
              else if (_resultados != null && (_resultados!['exito'] == false || _resultados!['detecciones'] == null || (_resultados!['detecciones'] as List).isEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Card(
                    elevation: 1,
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, color: Colors.orange.shade800, size: 54),
                          const SizedBox(height: 10),
                          Text(
                            _resultados!['mensaje']?.toString() ?? 'No se detectó ningún artrópodo en la imagen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Esta foto no se guardó en el historial. Intenta tomar una nueva foto donde el artrópodo esté más enfocado, centrado o con mejor iluminación.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.brown.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
