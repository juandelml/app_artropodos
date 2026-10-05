import 'package:flutter/material.dart';
import '../modelos/usuario_model.dart';
import '../servicios/auth_service.dart';
import 'pantalla_login.dart';

class DialogoPerfil {
  static void mostrar(BuildContext context, UsuarioModel? usuario) {
    if (usuario == null) return;

    final theme = Theme.of(context);
    final fecha = usuario.fechaRegistro;
    final fechaStr = fecha != null
        ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
        : 'Desconocida';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra superior de arrastre
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                // Avatar con inicial y Rol
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: usuario.esAdmin
                          ? Colors.amber.shade100
                          : Colors.green.shade100,
                      child: Text(
                        usuario.nombre.isNotEmpty
                            ? usuario.nombre[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: usuario.esAdmin
                              ? Colors.amber.shade900
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                    if (usuario.esAdmin)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.security,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nombre completo
                Text(
                  usuario.nombreCompleto.isNotEmpty
                      ? usuario.nombreCompleto
                      : usuario.username,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Username público
                Text(
                  '@${usuario.username}',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Chip de Rol
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: usuario.esAdmin
                        ? Colors.amber.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: usuario.esAdmin
                          ? Colors.amber.shade400
                          : Colors.green.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        usuario.esAdmin ? Icons.shield : Icons.remove_red_eye,
                        size: 14,
                        color: usuario.esAdmin
                            ? Colors.amber.shade900
                            : Colors.green.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        usuario.esAdmin ? 'Administrador' : 'Observador',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: usuario.esAdmin
                              ? Colors.amber.shade900
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 8),

                // Detalles adicionales
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.email_outlined, color: Colors.grey),
                  title: const Text('Correo electrónico'),
                  subtitle: Text(usuario.email),
                ),
                if (usuario.institucion.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.school_outlined, color: Colors.grey),
                    title: const Text('Institución'),
                    subtitle: Text(usuario.institucion),
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                  title: const Text('Fecha de registro'),
                  subtitle: Text(fechaStr),
                ),

                const SizedBox(height: 16),

                // Botón Cerrar Sesión
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await AuthService.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PantallaLogin(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
