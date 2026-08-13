import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'pantalla_detalle_deteccion.dart';
import 'servicios/api_service.dart';

class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key});

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  List<dynamic> avistamientos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    fetchUbicaciones();
  }

  Future<void> fetchUbicaciones() async {
    try {
      final List<dynamic>? datos = await ApiService.obtenerHistorial();

      if (datos != null) {
        setState(() {
          // Filtramos solo los registros que tengan coordenadas válidas
          avistamientos = datos.where((item) {
            return item['latitud'] != null && item['longitud'] != null;
          }).toList();
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
        debugPrint('Error al obtener historial de la API');
      }
    } catch (e) {
      setState(() => cargando = false);
      debugPrint('Error al conectar con la API: $e');
    }
  }

  void _mostrarDetalleBottomSheet(Map<String, dynamic> avistamiento) {
    // Tratamos de obtener el nombre de la especie si existe la clasificación
    String clase = 'Artrópodo Desconocido';
    String confianza = '';
    
    if (avistamiento['detecciones'] != null && 
        (avistamiento['detecciones'] as List).isNotEmpty) {
      clase = avistamiento['detecciones'][0]['clase'];
      confianza = avistamiento['detecciones'][0]['confianza'];
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return InkWell(
          onTap: () {
            // Cerramos el BottomSheet
            Navigator.pop(context);
            // Navegamos a la pantalla de detalle
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PantallaDetalleDeteccion(registro: avistamiento),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen del bicho
              if (avistamiento['imagen_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    // Ojo: si estás probando localhost en físico, la URL
                    // que regresa Django podría requerir ajustes.
                    (avistamiento['imagen_url'] as String).startsWith('http') 
                        ? avistamiento['imagen_url'] 
                        : "${ApiService.baseUrlHost}${avistamiento['imagen_url']}",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              
              // Información de la especie
              Text(
                clase,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (confianza.isNotEmpty)
                Text(
                  'Confianza: $confianza',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                
              const SizedBox(height: 10),
              // Fecha
              if (avistamiento['fecha_hora'] != null)
                Text(
                  'Registrado el: ${DateTime.parse(avistamiento['fecha_hora']).toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Avistamientos'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: const MapOptions(
                // Centrado inicial en México (puedes ajustarlo)
                initialCenter: LatLng(21.1232, -101.6521), // Coordinadas de Ejemplo (León, Gto)
                initialZoom: 5.5,
              ),
              children: [
                // Capa de los mapas de OpenStreetMap
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tu_dominio.app_artropodos',
                ),
                // Capa de los marcadores con clustering
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(40, 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: avistamientos.map((avistamiento) {
                      final double lat = avistamiento['latitud'];
                      final double lon = avistamiento['longitud'];

                      return Marker(
                        point: LatLng(lat, lon),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _mostrarDetalleBottomSheet(avistamiento),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 45,
                          ),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blue.shade700,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
  }
}
