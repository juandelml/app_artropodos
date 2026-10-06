import 'package:flutter/material.dart';
import 'servicios/api_service.dart';
import 'servicios/auth_service.dart';
import 'pantalla_detalle_deteccion.dart';
import 'pantallas/dialogo_perfil.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  Future<List<dynamic>?>? _historialFuture;
  bool _soloMisCapturasAdmin = false;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  void _cargarHistorial() {
    final usuarioActual = AuthService.usuarioActualNotifier.value;
    final esObservador = usuarioActual != null && !usuarioActual.esAdmin;
    setState(() {
      _historialFuture = ApiService.obtenerHistorial(
        soloMios: esObservador ? true : _soloMisCapturasAdmin,
      );
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

  Widget _construirEstadoVacio(bool esAdmin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.photo_library_outlined, size: 54, color: Colors.green.shade800),
            ),
            const SizedBox(height: 18),
            Text(
              esAdmin ? 'No hay avistamientos en el sistema' : 'No tienes avistamientos todavía',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              esAdmin
                  ? 'Cuando los observadores capturen artrópodos, aparecerán registrados aquí.'
                  : 'Toma o sube una fotografía desde la pestaña "Capturar" para comenzar tu colección personal de artrópodos.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarHistorial,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = AuthService.usuarioActualNotifier.value;
    final esAdmin = usuarioActual?.esAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(esAdmin ? 'Historial de Avistamientos' : 'Mis Avistamientos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarHistorial,
            tooltip: 'Actualizar historial',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 4.0),
            child: IconButton(
              tooltip: usuarioActual != null
                  ? '@${usuarioActual.username} (${usuarioActual.esAdmin ? 'Admin' : 'Observador'})'
                  : 'Perfil',
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: esAdmin
                    ? Colors.amber.shade200
                    : Colors.green.shade200,
                child: Text(
                  usuarioActual != null && usuarioActual.nombre.isNotEmpty
                      ? usuarioActual.nombre[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: esAdmin
                        ? Colors.amber.shade900
                        : Colors.green.shade900,
                  ),
                ),
              ),
              onPressed: () => DialogoPerfil.mostrar(context, usuarioActual),
            ),
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
            return _construirEstadoVacio(esAdmin);
          }

          final todosLosRegistros = snapshot.data!;

          // Filtro estricto: para observador solo sus propias capturas
          final registros = (!esAdmin && usuarioActual != null)
              ? todosLosRegistros.where((reg) {
                  final regUserId = reg['usuario_id']?.toString();
                  final regUsername = reg['usuario']?.toString();
                  return (regUserId != null && regUserId == usuarioActual.id.toString()) ||
                         (regUsername != null && regUsername == usuarioActual.username);
                }).toList()
              : (_soloMisCapturasAdmin && usuarioActual != null)
                  ? todosLosRegistros.where((reg) {
                      final regUserId = reg['usuario_id']?.toString();
                      final regUsername = reg['usuario']?.toString();
                      return (regUserId != null && regUserId == usuarioActual.id.toString()) ||
                             (regUsername != null && regUsername == usuarioActual.username);
                    }).toList()
                  : todosLosRegistros;

          if (registros.isEmpty) {
            return _construirEstadoVacio(esAdmin);
          }

          return RefreshIndicator(
            onRefresh: () async => _cargarHistorial(),
            child: Column(
              children: [
                if (esAdmin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text('Todos (${todosLosRegistros.length})'),
                          selected: !_soloMisCapturasAdmin,
                          onSelected: (val) {
                            setState(() {
                              _soloMisCapturasAdmin = false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: Text(
                            'Mis capturas (${todosLosRegistros.where((r) => r['usuario_id']?.toString() == usuarioActual?.id.toString() || r['usuario']?.toString() == usuarioActual?.username).length})',
                          ),
                          selected: _soloMisCapturasAdmin,
                          onSelected: (val) {
                            setState(() {
                              _soloMisCapturasAdmin = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
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
                      final puedeBorrar = esAdmin ||
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
                                              (usuarioIdCaptura != null && usuarioActual != null && usuarioIdCaptura == usuarioActual.id.toString())
                                                  ? '@$usernameCaptura (Tú)'
                                                  : '@$usernameCaptura',
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
