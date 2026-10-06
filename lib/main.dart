import 'package:flutter/material.dart';
import 'servicios/auth_service.dart';
import 'pantallas/pantalla_login.dart';
import 'pantallas/pantalla_dashboard.dart';
import 'pantallas/pantalla_captura.dart';
import 'pantalla_historial.dart';
import 'pantalla_mapa.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.inicializarSesion();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clasificador de Artrópodos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: ValueListenableBuilder(
        valueListenable: AuthService.usuarioActualNotifier,
        builder: (context, usuario, _) {
          return usuario != null
              ? const PantallaPrincipal()
              : const PantallaLogin();
        },
      ),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indiceActual = 0;

  void _cambiarPestana(int nuevoIndice) {
    setState(() {
      _indiceActual = nuevoIndice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: [
          // 0: Dashboard (Inicio) con métricas y capturas recientes
          PantallaDashboard(onCambiarTab: _cambiarPestana),

          // 1: Nueva Captura (Cámara / Galería y análisis)
          const PantallaCaptura(),

          // 2: Historial completo de avistamientos
          const PantallaHistorial(),

          // 3: Mapa interactivo con clusters
          const PantallaMapa(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: _cambiarPestana,
        indicatorColor: Colors.green.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.green),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_a_photo_outlined),
            selectedIcon: Icon(Icons.add_a_photo, color: Colors.green),
            label: 'Capturar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Colors.green),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Colors.green),
            label: 'Mapa',
          ),
        ],
      ),
    );
  }
}