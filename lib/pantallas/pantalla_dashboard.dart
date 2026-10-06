import 'package:flutter/material.dart';
import '../servicios/api_service.dart';
import '../servicios/auth_service.dart';
import '../modelos/usuario_model.dart';
import '../pantalla_detalle_deteccion.dart';
import 'dialogo_perfil.dart';

class PantallaDashboard extends StatefulWidget {
  final Function(int) onCambiarTab;

  const PantallaDashboard({
    super.key,
    required this.onCambiarTab,
  });

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends State<PantallaDashboard> {
  bool _cargando = true;
  List<dynamic> _todosLosRegistros = [];
  List<dynamic> _misRegistros = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final registros = await ApiService.obtenerHistorial();
      if (!mounted) return;

      final usuarioActual = AuthService.usuarioActualNotifier.value;

      if (registros != null) {
        // Filtrar las capturas del usuario activo
        final misCapturas = registros.where((item) {
          if (usuarioActual == null) return false;
          final usuarioIdItem = item['usuario_id']?.toString();
          final usuarioUsernameItem = item['usuario']?.toString();
          return (usuarioIdItem != null && usuarioIdItem == usuarioActual.id.toString()) ||
              (usuarioUsernameItem != null && usuarioUsernameItem == usuarioActual.username);
        }).toList();

        setState(() {
          _todosLosRegistros = registros;
          _misRegistros = misCapturas;
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "Reciente";
    try {
      final fecha = DateTime.parse(fechaIso).toLocal();
      return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
    } catch (_) {
      return "Reciente";
    }
  }

  int _contarEspeciesUnicas() {
    final especies = <String>{};
    for (var reg in _todosLosRegistros) {
      final dets = reg['detecciones'] as List<dynamic>?;
      if (dets != null) {
        for (var d in dets) {
          if (d['clase'] != null) {
            especies.add(d['clase'].toString());
          }
        }
      }
    }
    return especies.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = AuthService.usuarioActualNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.pest_control, color: Colors.green.shade800),
            const SizedBox(width: 8),
            const Text(
              'Artrópodos AI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar dashboard',
            onPressed: _cargarDatos,
          ),
          Padding(
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
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta de Bienvenida
              _construirBannerBienvenida(usuario),
              const SizedBox(height: 18),

              // 2. Métricas rápidas (KPIs)
              _construirTarjetasKPI(),
              const SizedBox(height: 18),

              // 3. Botón de acción rápida: Nueva Captura
              _construirBannerAccionRapida(),
              const SizedBox(height: 24),

              // 4. Tus Capturas Recientes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tus Capturas Recientes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (_misRegistros.isNotEmpty)
                    TextButton(
                      onPressed: () => widget.onCambiarTab(2), // Ir a Historial
                      child: Text(
                        'Ver todas (${_misRegistros.length})',
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _construirSeccionMisCapturas(),
              const SizedBox(height: 24),

              // 5. Actividad reciente de la comunidad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exploraciones de la Comunidad',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onCambiarTab(3), // Ir a Mapa
                    child: Text(
                      'Ver en Mapa',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _construirSeccionComunidad(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBannerBienvenida(UsuarioModel? usuario) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade800,
            Colors.green.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${usuario?.nombre.isNotEmpty == true ? usuario!.nombre : (usuario?.username ?? 'Investigador')}!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario?.institucion.isNotEmpty == true
                          ? '${usuario!.institucion} • @${usuario.username}'
                          : '@${usuario?.username ?? 'usuario'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (usuario?.esAdmin ?? false) ? Colors.amber.shade400 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (usuario?.esAdmin ?? false) ? 'ADMIN' : 'OBSERVADOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: (usuario?.esAdmin ?? false) ? Colors.brown.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Listo para clasificar artrópodos mediante visión por computadora.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetasKPI() {
    final int especiesCount = _contarEspeciesUnicas();

    return Row(
      children: [
        Expanded(
          child: _construirItemKPI(
            titulo: 'Tus Capturas',
            valor: _cargando ? '...' : _misRegistros.length.toString(),
            icono: Icons.camera_alt,
            color: Colors.green.shade700,
            fondo: Colors.green.shade50,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _construirItemKPI(
            titulo: 'Comunidad',
            valor: _cargando ? '...' : _todosLosRegistros.length.toString(),
            icono: Icons.public,
            color: Colors.blue.shade700,
            fondo: Colors.blue.shade50,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _construirItemKPI(
            titulo: 'Órdenes',
            valor: _cargando ? '...' : (especiesCount > 0 ? especiesCount.toString() : '7'),
            icono: Icons.biotech,
            color: Colors.amber.shade800,
            fondo: Colors.amber.shade50,
          ),
        ),
      ],
    );
  }

  Widget _construirItemKPI({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    required Color fondo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _construirBannerAccionRapida() {
    return InkWell(
      onTap: () => widget.onCambiarTab(1), // Cambia al tab de Nueva Captura
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade100.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Iniciar Nueva Captura',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toma o sube una fotografía para clasificar el ejemplar al instante.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.green.shade800, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _construirSeccionMisCapturas() {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_misRegistros.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_camera_back_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'Aún no tienes capturas registradas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Las fotos que clasifiques aparecerán aquí para acceso rápido.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => widget.onCambiarTab(1),
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Hacer mi primera captura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar las últimas capturas del usuario (hasta 6) en lista horizontal
    final ultimas = _misRegistros.take(6).toList();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ultimas.length,
        itemBuilder: (context, index) {
          final reg = ultimas[index];
          final dets = reg['detecciones'] as List<dynamic>? ?? [];
          final clase = dets.isNotEmpty && dets[0]['clase'] != null
              ? dets[0]['clase'].toString()
              : 'Artrópodo';
          final confianza = dets.isNotEmpty && dets[0]['confianza'] != null
              ? dets[0]['confianza'].toString()
              : '';
          final imgUrl = reg['imagen_url']?.toString();
          final fecha = _formatearFecha(reg['fecha_hora']?.toString());

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12, bottom: 4),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PantallaDetalleDeteccion(registro: reg),
                    ),
                  ).then((_) => _cargarDatos());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Miniatura
                    Expanded(
                      child: imgUrl != null
                          ? Image.network(
                              imgUrl.startsWith('http') ? imgUrl : '${ApiService.baseUrlHost}$imgUrl',
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: Colors.green.shade50,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: Colors.green.shade50,
                              child: const Icon(Icons.pest_control, color: Colors.green),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clase,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (confianza.isNotEmpty)
                            Text(
                              confianza,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            fecha,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _construirSeccionComunidad() {
    if (_cargando) {
      return const SizedBox(height: 60);
    }

    if (_todosLosRegistros.isEmpty) {
      return const Center(child: Text('No hay avistamientos en el sistema.'));
    }

    // Últimos 3 registros en general
    final recientes = _todosLosRegistros.take(4).toList();

    return Column(
      children: recientes.map((reg) {
        final dets = reg['detecciones'] as List<dynamic>? ?? [];
        final clase = dets.isNotEmpty && dets[0]['clase'] != null
            ? dets[0]['clase'].toString()
            : 'Artrópodo';
        final imgUrl = reg['imagen_url']?.toString();
        final autor = reg['usuario']?.toString() ?? 'Anónimo';
        final fecha = _formatearFecha(reg['fecha_hora']?.toString());
        final bool tieneGps = reg['latitud'] != null && reg['longitud'] != null;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imgUrl != null
                  ? Image.network(
                      imgUrl.startsWith('http') ? imgUrl : '${ApiService.baseUrlHost}$imgUrl',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.green.shade50,
                        child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.green.shade50,
                      child: const Icon(Icons.pest_control, color: Colors.green),
                    ),
            ),
            title: Text(clase, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Row(
              children: [
                Icon(Icons.person, size: 12, color: Colors.green.shade800),
                const SizedBox(width: 4),
                Text('@$autor', style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text('• $fecha', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (tieneGps) ...[
                  const SizedBox(width: 4),
                  const Text('📍', style: TextStyle(fontSize: 10)),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaDetalleDeteccion(registro: reg),
                ),
              ).then((_) => _cargarDatos());
            },
          ),
        );
      }).toList(),
    );
  }
}
