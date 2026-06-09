import 'package:flutter/material.dart';
import 'servicios/api_service.dart';

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

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "Fecha desconocida";
    try {
      DateTime fecha = DateTime.parse(fechaIso).toLocal();
      return "${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fechaIso;
    }
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
                            "http://10.13.4.12:8000$rutaImagenUrl", // Asegurar ruta absoluta a Django
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
                      Text(_formatearFecha(registro['fecha'])), // Asumimos campo 'fecha'
                      if (latitud != null && longitud != null)
                        Text(
                          "📍 Ubicación guardada",
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: A futuro aquí podemos abrir los detalles mostrando de nuevo el lienzo
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
