import 'package:flutter/material.dart';
import 'servicios/api_service.dart';
import 'servicios/auth_service.dart';
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
      return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} - ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fechaIso;
    }
  }

  DateTime _parsearFechaLocal(String fechaIso) {
    final tieneZonaHoraria = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(fechaIso);
    final fecha = DateTime.parse(tieneZonaHoraria ? fechaIso : '${fechaIso}Z');
    return fecha.toLocal();
  }

  Future<void> _confirmarYEliminar(String idAvistamiento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar avistamiento'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este registro del historial? Esta acción no se puede deshacer.',
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

    if (confirmar == true) {
      final exito = await ApiService.eliminarAvistamiento(idAvistamiento);
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avistamiento eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarHistorial();
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
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = AuthService.usuarioActualNotifier.value;

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
              final idAvistamiento = registro['id']?.toString() ?? '';
              final detecciones = registro['detecciones'] as List<dynamic>? ?? [];
              final numDetecciones = detecciones.length;
              final latitud = registro['latitud'];
              final longitud = registro['longitud'];
              final rutaImagenUrl = registro['imagen_url'];
              final fechaIso = _obtenerFechaIso(registro);
              final usernameCaptura = registro['usuario']?.toString() ?? 'Anónimo';
              final institucionCaptura = registro['institucion']?.toString() ?? '';
              final usuarioIdCaptura = registro['usuario_id']?.toString();

              // El usuario puede borrar si es Admin o si es el dueño de la captura
              final puedeBorrar = (usuarioActual?.esAdmin ?? false) ||
                  (usuarioIdCaptura != null && usuarioActual != null && usuarioIdCaptura == usuarioActual.id.toString());

              // Identificar clase principal
              String clasePrincipal = 'Desconocido';
              if (numDetecciones > 0 && detecciones[0]['clase'] != null) {
                clasePrincipal = detecciones[0]['clase'];
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PantallaDetalleDeteccion(registro: registro),
                      ),
                    );
                    _cargarHistorial();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Miniatura de la imagen
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: rutaImagenUrl != null
                              ? Image.network(
                                  rutaImagenUrl.startsWith('http')
                                      ? rutaImagenUrl
                                      : "${ApiService.baseUrlHost}$rutaImagenUrl",
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.green.shade50,
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.green.shade50,
                                  child: const Icon(Icons.bug_report, size: 40, color: Colors.green),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // Datos del avistamiento
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clasePrincipal,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              // Usuario que realizó la captura
                              Row(
                                children: [
                                  Icon(Icons.person, size: 13, color: Colors.green.shade800),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '@$usernameCaptura',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (institucionCaptura.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '($institucionCaptura)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Detectados: $numDetecciones artrópodo${numDetecciones == 1 ? '' : 's'}",
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                              Text(
                                _formatearFecha(fechaIso),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                              if (latitud != null && longitud != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    "📍 Coordenadas guardadas",
                                    style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Acciones: Botón de borrar si es admin/dueño y flecha
                        Column(
                          children: [
                            if (puedeBorrar && idAvistamiento.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                tooltip: 'Eliminar avistamiento',
                                onPressed: () => _confirmarYEliminar(idAvistamiento),
                              ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
