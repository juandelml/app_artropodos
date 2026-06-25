import 'dart:io';
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
      child: FittedBox(
        fit: BoxFit.contain, // La magia: encoge todo el contenido para que quepa aquí
        child: SizedBox(
          // Creamos un lienzo interno del tamaño GIGANTE original
          width: imgAncho,
          height: imgAlto,
          child: Stack(
            children: [
              // Capa 1: La foto en su tamaño original
              Image.file(imagen),
              
              // Capa 2: Dibuja las cajas de las detecciones visibles
              if (detecciones != null)
                for (int i = 0; i < detecciones!.length; i++)
                  if (indicesVisibles.contains(i))
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BordeArthropodo(caja: detecciones![i]['caja_delimitadora']),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BordeArthropodo extends CustomPainter {
  final Map<String, dynamic> caja;

  _BordeArthropodo({required this.caja});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      // OJO: Como estamos dibujando en un lienzo de miles de píxeles que luego se va a encoger,
      // necesitamos que la pluma sea muy gruesa (ej. 25px) para que al encogerse no desaparezca.
      ..strokeWidth = 25.0; 

    try {
      final double x1 = double.parse(caja['x1'].toString());
      final double y1 = double.parse(caja['y1'].toString());
      final double x2 = double.parse(caja['x2'].toString());
      final double y2 = double.parse(caja['y2'].toString());

      // ¡Cero cálculos matemáticos! Dibujamos directamente usando lo que mandó Django
      canvas.drawRect(
        Rect.fromLTRB(x1, y1, x2, y2),
        paint,
      );
    } catch (e) {
      print("Error al dibujar: $e");
    }
  }

  @override
  bool shouldRepaint(_BordeArthropodo oldDelegate) {
    // Solo repintar si la caja cambió
    return caja != oldDelegate.caja;
  }
}