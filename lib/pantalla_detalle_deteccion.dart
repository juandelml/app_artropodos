import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'servicios/auth_service.dart';
import 'servicios/api_service.dart';

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
      final archivoLocal = widget.registro['archivo_local'];
      if (archivoLocal != null) {
        try {
          final File file = archivoLocal is File ? archivoLocal : File(archivoLocal.toString());
          if (await file.exists()) {
            final Uint8List bytes = await file.readAsBytes();
            final ui.Codec codec = await ui.instantiateImageCodec(bytes);
            final ui.FrameInfo frameInfo = await codec.getNextFrame();
            return frameInfo.image;
          }
        } catch (e) {
          print('[DETALLE] No se pudo cargar archivo local, intentando URL: $e');
        }
      }

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
    final usuarioActual = AuthService.usuarioActualNotifier.value;
    final idAvistamiento = widget.registro['id']?.toString() ?? '';
    final usuarioCaptura = widget.registro['usuario']?.toString() ?? 'Anónimo';
    final institucionCaptura = widget.registro['institucion']?.toString() ?? '';
    final usuarioIdCaptura = widget.registro['usuario_id']?.toString();

    final puedeBorrar = (usuarioActual?.esAdmin ?? false) ||
        (usuarioIdCaptura != null && usuarioActual != null && usuarioIdCaptura == usuarioActual.id.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Detección'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (puedeBorrar && idAvistamiento.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Eliminar avistamiento',
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar avistamiento'),
                    content: const Text(
                      '¿Estás seguro de que deseas eliminar este registro del historial?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirmar == true && context.mounted) {
                  final exito = await ApiService.eliminarAvistamiento(idAvistamiento);
                  if (context.mounted) {
                    if (exito) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Avistamiento eliminado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al eliminar el avistamiento'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
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
                  // Registrado por
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.green.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Registrado por: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          '@$usuarioCaptura',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        if (institucionCaptura.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '($institucionCaptura)',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
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
    if (uiImage.width <= 0 || uiImage.height <= 0 || size.width <= 0 || size.height <= 0) {
      return;
    }

    // Calcular escala para que la imagen quepa en el espacio (BoxFit.contain)
    final double scaleX = size.width / uiImage.width;
    final double scaleY = size.height / uiImage.height;
    final double scale = math.min(scaleX, scaleY);

    // Centrar la imagen dentro del tamaño del canvas disponible
    final double offsetX = (size.width - uiImage.width * scale) / 2;
    final double offsetY = (size.height - uiImage.height * scale) / 2;

    // Dibujar la imagen escalada
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.drawImage(uiImage, Offset.zero, Paint());

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

            // Dimensiones de la caja proyectadas en pantalla real
            final double cajaAnchoPantalla = (x2 - x1).abs() * scale;
            final double cajaAltoPantalla = (y2 - y1).abs() * scale;
            final double minDimCajaPantalla = math.min(cajaAnchoPantalla, cajaAltoPantalla);

            // Grosor responsivo: base ~2.5 px visuales en la pantalla del celular
            double grosorPantalla = 2.5;
            if (minDimCajaPantalla > 0 && minDimCajaPantalla < 25.0) {
              // Si la caja detectada es sumamente pequeña en pantalla, adelgazamos suavemente
              grosorPantalla = math.max(1.2, minDimCajaPantalla * 0.10);
            }

            final double grosor = (scale > 0) ? (grosorPantalla / scale) : 2.5;
            final paint = Paint()
              ..color = Colors.greenAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = grosor;

            // 1. Dibujar el rectángulo delimitador
            canvas.drawRect(
              Rect.fromLTRB(x1, y1, x2, y2),
              paint,
            );

            // 2. Dibujar etiqueta con clase y porcentaje de confianza
            final deteccionConfianza = _normalizarConfianzaValor(deteccion['confianza']);
            final String etiquetaTexto =
                '${deteccion['clase']?.toString() ?? 'Desconocido'} ${(deteccionConfianza * 100).toStringAsFixed(0)}%';

            // Tamaño de fuente responsivo: base ~11 px visuales en pantalla
            double fontSizePantalla = 11.0;
            if (minDimCajaPantalla > 0 && minDimCajaPantalla < 35.0) {
              fontSizePantalla = math.max(7.5, minDimCajaPantalla * 0.35);
            }
            final double fontSize = (scale > 0) ? (fontSizePantalla / scale) : (grosor * 2.0);

            final textPainter = TextPainter(
              text: TextSpan(
                text: etiquetaTexto,
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            // Rellenos (padding) responsivos en coordenadas de pantalla
            final double padHPantalla = 5.0;
            final double padVPantalla = 2.5;
            final double padH = (scale > 0) ? (padHPantalla / scale) : (grosor * 0.3);
            final double padV = (scale > 0) ? (padVPantalla / scale) : (grosor * 0.15);

            final double badgeWidth = textPainter.width + (padH * 2);
            final double badgeHeight = textPainter.height + (padV * 2);

            // Posicionar etiqueta asegurando que permanezca dentro de los límites
            double badgeX = x1;
            if (badgeX + badgeWidth > uiImage.width) {
              badgeX = math.max(0.0, uiImage.width - badgeWidth);
            }

            double badgeY = y1 - badgeHeight;
            if (badgeY < 0) {
              badgeY = y1; // si toca el borde superior de la foto, mostrar justo adentro
            }

            // Fondo translúcido con esquinas redondeadas para legibilidad perfecta
            final double radiusPantalla = 3.5;
            final double radius = (scale > 0) ? (radiusPantalla / scale) : (grosor * 0.15);

            final badgeRect = RRect.fromRectAndRadius(
              Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight),
              Radius.circular(radius),
            );
            final badgePaint = Paint()
              ..color = Colors.black.withValues(alpha: 0.78)
              ..style = PaintingStyle.fill;

            canvas.drawRRect(badgeRect, badgePaint);

            // Texto de la etiqueta
            textPainter.paint(
              canvas,
              Offset(badgeX + padH, badgeY + padV),
            );
          } catch (e) {
            debugPrint('Error dibujando detección: $e');
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

class _PantallaImagenCompleta extends StatefulWidget {
  final ui.Image uiImage;
  final List<dynamic> detecciones;
  final Set<int> indicesVisibles;

  const _PantallaImagenCompleta({
    required this.uiImage,
    required this.detecciones,
    required this.indicesVisibles,
  });

  @override
  State<_PantallaImagenCompleta> createState() => _PantallaImagenCompletaState();
}

class _PantallaImagenCompletaState extends State<_PantallaImagenCompleta> {
  final TransformationController _transformationController = TransformationController();

  void _onDoubleTap(TapDownDetails details) {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      final Matrix4 zoomed = Matrix4.identity()
        ..storage[0] = 2.5
        ..storage[5] = 2.5
        ..storage[12] = -position.dx * 1.5
        ..storage[13] = -position.dy * 1.5;
      _transformationController.value = zoomed;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

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
                  child: GestureDetector(
                    onDoubleTapDown: _onDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 6.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: CustomPaint(
                          painter: _PintorDetalleDeteccion(
                            uiImage: widget.uiImage,
                            detecciones: widget.detecciones,
                            indicesVisibles: widget.indicesVisibles,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Botón para regresar
                Positioned(
                  top: 12,
                  left: 12,
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
                // Insignia informativa de detecciones
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pest_control, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.indicesVisibles.length} artrópodo(s)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
