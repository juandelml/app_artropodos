import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

double _normalizarConfianzaValor(dynamic valor) {
  if (valor == null) return 0.0;

  if (valor is num) {
    final confianza = valor.toDouble();
    return confianza > 1.0
        ? (confianza / 100.0).clamp(0.0, 1.0)
        : confianza.clamp(0.0, 1.0);
  }

  final texto = valor.toString().trim().replaceAll('%', '');
  final confianza = double.tryParse(texto);
  if (confianza == null) return 0.0;
  return confianza > 1.0
      ? (confianza / 100.0).clamp(0.0, 1.0)
      : confianza.clamp(0.0, 1.0);
}

class PantallaDetalleDeteccion extends StatefulWidget {
  final Map<String, dynamic> registro;

  const PantallaDetalleDeteccion({
    super.key,
    required this.registro,
  });

  @override
  State<PantallaDetalleDeteccion> createState() =>
      _PantallaDetalleDeteccionState();
}

class _PantallaDetalleDeteccionState extends State<PantallaDetalleDeteccion> {
  late Future<ui.Image> _imagenFuture;
  late List<dynamic> _detecciones;
  late Set<int> _indicesVisibles;

  @override
  void initState() {
    super.initState();
    _detecciones = widget.registro['detecciones'] as List<dynamic>? ?? [];
    _indicesVisibles = Set<int>.from(
        List<int>.generate(_detecciones.length, (i) => i)); // Mostrar todos
    _imagenFuture = _cargarImagen();
  }

  Future<ui.Image> _cargarImagen() async {
    try {
      final rutaImagen = widget.registro['imagen_url'] as String?;
      if (rutaImagen == null || rutaImagen.isEmpty) {
        throw Exception('No se encontró URL de imagen');
      }

      // Django devuelve URL completa, usar directamente
      print('[DETALLE] Cargando imagen desde: $rutaImagen');

      final response = await http.get(Uri.parse(rutaImagen));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        return frameInfo.image;
      } else {
        throw Exception('Error al descargar imagen: ${response.statusCode}');
      }
    } catch (e) {
      print('[DETALLE] Error cargando imagen: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    double? latitud;
    if (widget.registro['latitud'] != null) {
      latitud = double.tryParse(widget.registro['latitud'].toString());
    }
    double? longitud;
    if (widget.registro['longitud'] != null) {
      longitud = double.tryParse(widget.registro['longitud'].toString());
    }
    final fecha = (widget.registro['fecha_hora'] ?? widget.registro['fecha'] ?? widget.registro['created_at'])?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Detección'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== SECCIÓN 1: IMAGEN CON DETECCIONES ==========
            Container(
              color: Colors.black12,
              padding: const EdgeInsets.all(8),
              child: FutureBuilder<ui.Image>(
                future: _imagenFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: Text('Error cargando imagen:\n${snapshot.error}'),
                      ),
                    );
                  }

                  final uiImage = snapshot.data!;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _PantallaImagenCompleta(
                            uiImage: uiImage,
                            detecciones: _detecciones,
                            indicesVisibles: _indicesVisibles,
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: 300,
                      child: CustomPaint(
                        painter: _PintorDetalleDeteccion(
                          uiImage: uiImage,
                          detecciones: _detecciones,
                          indicesVisibles: _indicesVisibles,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ========== SECCIÓN 2: INFO GENERAL ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de la Detección',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (fecha != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Fecha: ${_formatearFecha(fecha)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (latitud != null && longitud != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicación: ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navegar a mapa mostrando esta ubicación
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PantallaMapaDetalle(
                                    latitud: latitud!,
                                    longitud: longitud!,
                                    detecciones: _detecciones,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Ver en Mapa'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========== SECCIÓN 3: LISTA DE DETECCIONES ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artrópodos Detectados (${_detecciones.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detecciones.length,
              itemBuilder: (context, index) {
                final deteccion = _detecciones[index];
                final clase = deteccion['clase']?.toString() ?? 'Desconocido';
                final confianza = _normalizarConfianza(deteccion['confianza']);
                final caja = deteccion['caja_delimitadora'] as Map?;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                clase,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(confianza * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (caja != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Posición: (${_formatearCoordenada(caja['x1'])}, ${_formatearCoordenada(caja['y1'])}) - (${_formatearCoordenada(caja['x2'])}, ${_formatearCoordenada(caja['y2'])})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = _parsearFechaLocal(fechaIso);
      return "${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fechaIso;
    }
  }

  DateTime _parsearFechaLocal(String fechaIso) {
    final tieneZonaHoraria = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(fechaIso);
    final fecha = DateTime.parse(tieneZonaHoraria ? fechaIso : '${fechaIso}Z');
    return fecha.toLocal();
  }

  String _formatearCoordenada(dynamic valor) {
    try {
      return double.parse(valor.toString()).toStringAsFixed(0);
    } catch (e) {
      return valor.toString();
    }
  }

  double _normalizarConfianza(dynamic valor) {
    return _normalizarConfianzaValor(valor);
  }
}

// ========== CUSTOM PAINTER PARA DIBUJAR BOUNDING BOXES ==========
class _PintorDetalleDeteccion extends CustomPainter {
  final ui.Image uiImage;
  final List<dynamic> detecciones;
  final Set<int> indicesVisibles;

  _PintorDetalleDeteccion({
    required this.uiImage,
    required this.detecciones,
    required this.indicesVisibles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calcular escala para que la imagen quepa en el espacio
    final double scaleX = size.width / uiImage.width;
    final double scaleY = size.height / uiImage.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // Centrar la imagen
    final double offsetX = (size.width - uiImage.width * scale) / 2;
    final double offsetY = (size.height - uiImage.height * scale) / 2;

    // Dibujar la imagen escalada
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.drawImage(uiImage, Offset.zero, Paint());

    // Dibujar bounding boxes
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < detecciones.length; i++) {
      if (indicesVisibles.contains(i)) {
        final deteccion = detecciones[i];
        final caja = deteccion['caja_delimitadora'] as Map?;

        if (caja != null) {
          try {
            final double x1 = double.parse(caja['x1'].toString());
            final double y1 = double.parse(caja['y1'].toString());
            final double x2 = double.parse(caja['x2'].toString());
            final double y2 = double.parse(caja['y2'].toString());

            canvas.drawRect(
              Rect.fromLTRB(x1, y1, x2, y2),
              paint,
            );

            // Dibujar etiqueta con nombre y confianza
            final deteccionConfianza = _normalizarConfianzaValor(deteccion['confianza']);
            final textPainter = TextPainter(
              text: TextSpan(
                text:
                    '${deteccion['clase']?.toString() ?? 'Desconocido'} ${(deteccionConfianza * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(x1, y1 - 20));
          } catch (e) {
            print('Error dibujando detección: $e');
          }
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorDetalleDeteccion oldDelegate) {
    return uiImage != oldDelegate.uiImage ||
        detecciones != oldDelegate.detecciones ||
        indicesVisibles != oldDelegate.indicesVisibles;
  }
}

class _PantallaImagenCompleta extends StatelessWidget {
  final ui.Image uiImage;
  final List<dynamic> detecciones;
  final Set<int> indicesVisibles;

  const _PantallaImagenCompleta({
    required this.uiImage,
    required this.detecciones,
    required this.indicesVisibles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(64),
                    constrained: false,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: uiImage.width.toDouble(),
                            height: uiImage.height.toDouble(),
                            child: CustomPaint(
                              painter: _PintorDetalleDeteccion(
                                uiImage: uiImage,
                                detecciones: detecciones,
                                indicesVisibles: indicesVisibles,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Regresar',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ========== PANTALLA DE MAPA CON UBICACIÓN ==========
class PantallaMapaDetalle extends StatelessWidget {
  final double latitud;
  final double longitud;
  final List<dynamic> detecciones;

  const PantallaMapaDetalle({
    super.key,
    required this.latitud,
    required this.longitud,
    required this.detecciones,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación del Avistamiento'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(latitud, longitud),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.tu_dominio.app_artropodos',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(latitud, longitud),
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 45,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Artrópodos en esta ubicación: ${detecciones.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              detecciones
                  .map((d) => d['clase'] ?? 'Desconocido')
                  .join(', '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
