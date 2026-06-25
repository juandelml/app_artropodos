import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    // IMPORTANTE: Reemplaza esta IP con tu IP local real o la de tu backend
    // Por ejemplo: 'http://192.168.1.100:8000/api/historial/'
    // Si pruebas en el emulador de Android usa 'http://10.0.2.2:8000/api/historial/'
    final url = Uri.parse('http://10.0.2.2:8000/api/historial/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> datos = json.decode(response.body);

        setState(() {
          // Filtramos solo los registros que tengan coordenadas válidas
          avistamientos = datos.where((item) {
            return item['latitud'] != null && item['longitud'] != null;
          }).toList();
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
        debugPrint('Error en la petición: ${response.statusCode}');
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
        return Padding(
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
                    avistamiento['imagen_url'],
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
                // Capa de los marcadores
                MarkerLayer(
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
                ),
              ],
            ),
    );
  }
}
