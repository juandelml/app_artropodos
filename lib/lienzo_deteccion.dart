import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LienzoDeteccion extends StatelessWidget {
  final File imagen;
  final List<dynamic>? detecciones;
  final Set<int> indicesVisibles;
  final double imgAncho; // <-- Recibimos el ancho real
  final double imgAlto;  // <-- Recibimos el alto real

  const LienzoDeteccion({
    super.key,
    required this.imagen,
    required this.detecciones,
    required this.indicesVisibles,
    required this.imgAncho,
    required this.imgAlto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 350, // Altura en la pantalla del celular
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Espacio real en pantalla disponible para mostrar la imagen
          final double anchoDisponible = constraints.maxWidth;
          final double altoDisponible = constraints.maxHeight;

          // Escala exacta que FittedBox aplica para ajustar la imagen a la pantalla
          final double escala = (imgAncho > 0 && imgAlto > 0)
              ? math.min(anchoDisponible / imgAncho, altoDisponible / imgAlto)
              : 1.0;

          return FittedBox(
            fit: BoxFit.contain, // Encoge todo el contenido para que quepa aquí
            child: SizedBox(
              // Creamos un lienzo interno del tamaño original
              width: imgAncho,
              height: imgAlto,
              child: Stack(
                children: [
                  // Capa 1: La foto en su tamaño original
                  Image.file(imagen),
                  
                  // Capa 2: Dibuja las cajas de las detecciones visibles con sus etiquetas
                  if (detecciones != null)
                    for (int i = 0; i < detecciones!.length; i++)
                      if (indicesVisibles.contains(i))
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BordeArthropodo(
                              caja: detecciones![i]['caja_delimitadora'],
                              clase: detecciones![i]['clase']?.toString(),
                              escala: escala,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BordeArthropodo extends CustomPainter {
  final Map<String, dynamic> caja;
  final String? clase;
  final double escala;

  _BordeArthropodo({
    required this.caja,
    this.clase,
    this.escala = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final double x1 = double.parse(caja['x1'].toString());
      final double y1 = double.parse(caja['y1'].toString());
      final double x2 = double.parse(caja['x2'].toString());
      final double y2 = double.parse(caja['y2'].toString());

      // Dimensiones de la caja proyectadas en pantalla
      final double cajaAnchoPantalla = (x2 - x1).abs() * escala;
      final double cajaAltoPantalla = (y2 - y1).abs() * escala;
      final double minDimCajaPantalla = math.min(cajaAnchoPantalla, cajaAltoPantalla);

      // Grosor responsivo: siempre ~2.2 px visuales en la pantalla del celular,
      // independientemente de si la foto original es de 500px o de 12000px.
      double grosorPantalla = 2.2;
      if (minDimCajaPantalla > 0 && minDimCajaPantalla < 25.0) {
        // Si la caja detectada es sumamente pequeña en pantalla, adelgazamos suavemente
        grosorPantalla = math.max(1.2, minDimCajaPantalla * 0.10);
      }

      // Convertimos el grosor deseado en pantalla a coordenadas del lienzo original
      final double grosor = (escala > 0) ? (grosorPantalla / escala) : 20.0;

      final paint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor;

      // 1. Dibujamos el rectángulo de la caja delimitadora
      canvas.drawRect(
        Rect.fromLTRB(x1, y1, x2, y2),
        paint,
      );

      // 2. Dibujamos la etiqueta de la clase si está presente
      if (clase != null && clase!.trim().isNotEmpty) {
        // Tamaño de texto en pantalla (~10 px visuales para que sea compacto y legible)
        double fontSizePantalla = 10.0;
        if (minDimCajaPantalla > 0 && minDimCajaPantalla < 35.0) {
          fontSizePantalla = math.max(7.0, minDimCajaPantalla * 0.35);
        }

        final double fontSize = (escala > 0) ? (fontSizePantalla / escala) : (grosor * 2.0);

        final textPainter = TextPainter(
          text: TextSpan(
            text: clase,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Rellenos (padding) responsivos en coordenadas de pantalla
        final double padHPantalla = 4.5;
        final double padVPantalla = 2.5;
        final double padH = (escala > 0) ? (padHPantalla / escala) : (grosor * 0.3);
        final double padV = (escala > 0) ? (padVPantalla / escala) : (grosor * 0.15);

        final double badgeWidth = textPainter.width + (padH * 2);
        final double badgeHeight = textPainter.height + (padV * 2);

        // Posicionar etiqueta: encima de la caja delimitadora si cabe, o justo adentro si toca el borde superior
        double badgeX = x1;
        if (badgeX + badgeWidth > size.width) {
          badgeX = math.max(0.0, size.width - badgeWidth);
        }

        double badgeY = y1 - badgeHeight;
        if (badgeY < 0) {
          badgeY = y1;
        }

        // Fondo de la etiqueta con esquinas redondeadas
        final double radiusPantalla = 3.0;
        final double radius = (escala > 0) ? (radiusPantalla / escala) : (grosor * 0.15);

        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight),
          Radius.circular(radius),
        );
        final badgePaint = Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.fill;

        canvas.drawRRect(badgeRect, badgePaint);

        // Texto de la etiqueta
        textPainter.paint(
          canvas,
          Offset(badgeX + padH, badgeY + padV),
        );
      }
    } catch (e) {
      debugPrint("Error al dibujar detección: $e");
    }
  }

  @override
  bool shouldRepaint(_BordeArthropodo oldDelegate) {
    // Repintar si la caja, la clase o la escala cambiaron
    return caja != oldDelegate.caja ||
        clase != oldDelegate.clase ||
        escala != oldDelegate.escala;
  }
}