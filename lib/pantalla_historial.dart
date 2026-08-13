import 'package:flutter/material.dart';
import 'servicios/api_service.dart';
import 'pantalla_detalle_deteccion.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  Future<List<dynamic>?>? _historialFuture;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  void _cargarHistorial() {
    setState(() {
      _historialFuture = ApiService.obtenerHistorial();
    });
  }

  String? _obtenerFechaIso(Map<String, dynamic> registro) {
    final fecha = registro['fecha_hora'] ?? registro['fecha'] ?? registro['created_at'];
    if (fecha == null) return null;
    return fecha.toString();
  }

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "Fecha desconocida";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Avistamientos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorial,
            tooltip: 'Actualizar historial',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>?>(
        future: _historialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Todavía no hay avistamientos guardados."));
          }

          final registros = snapshot.data!;

          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, index) {
              final registro = registros[index];
              final detecciones = registro['detecciones'] as List<dynamic>? ?? [];
              final numDetecciones = detecciones.length;
              final latitud = registro['latitud'];
              final longitud = registro['longitud'];
              final rutaImagenUrl = registro['imagen_url']; // Asumimos que Django envía un 'imagen_url'
              final fechaIso = _obtenerFechaIso(registro);
              
              // Intentar obtener la clase principal (el primer artrópodo detectado)
              String clasePrincipal = 'Desconocido';
              if (numDetecciones > 0 && detecciones[0]['clase'] != null) {
                 clasePrincipal = detecciones[0]['clase'];
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: rutaImagenUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            rutaImagenUrl.startsWith('http') ? rutaImagenUrl : "${ApiService.baseUrlHost}$rutaImagenUrl",
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 60),
                          ),
                        )
                      : const Icon(Icons.bug_report, size: 60, color: Colors.green),
                  title: Text(
                    clasePrincipal,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Avistamientos en foto: $numDetecciones"),
                      Text(_formatearFecha(fechaIso)),
                      if (latitud != null && longitud != null)
                        Text(
                          "📍 Ubicación guardada",
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PantallaDetalleDeteccion(registro: registro),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
