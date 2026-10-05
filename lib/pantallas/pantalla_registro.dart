import 'package:flutter/material.dart';
import '../servicios/auth_service.dart';
import '../main.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _institucionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _rolSeleccionado = 'observador';
  bool _cargando = false;
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _institucionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final resultado = await AuthService.signup(
      nombre: _nombreController.text,
      apellidos: _apellidosController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      institucion: _institucionController.text,
      rol: _rolSeleccionado,
    );

    if (!mounted) return;
    setState(() => _cargando = false);

    if (resultado['exito'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Cuenta creada exitosamente como ${_rolSeleccionado == 'admin' ? 'Administrador' : 'Observador'}!'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // Redirigir a la pantalla principal limpiando el stack de navegación
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['error'] ?? 'Error al registrar usuario'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título y explicación
                    Text(
                      'Crea tu cuenta',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Únete a la plataforma para registrar y clasificar avistamientos de artrópodos.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta con los campos
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Nombre y Apellidos
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nombreController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre *',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _apellidosController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: 'Apellidos *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 2. Nombre de usuario (username para las capturas)
                            TextFormField(
                              controller: _usernameController,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Nombre de usuario (@username) *',
                                helperText: 'Este nombre aparecerá públicamente en tus capturas',
                                prefixIcon: const Icon(Icons.alternate_email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Por favor ingresa un nombre de usuario';
                                }
                                if (val.contains(' ')) {
                                  return 'El nombre de usuario no puede contener espacios';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 3. Correo electrónico
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Correo Electrónico *',
                                helperText: 'Lo usarás para iniciar sesión',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Ingresa un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 4. Institución (opcional)
                            TextFormField(
                              controller: _institucionController,
                              decoration: InputDecoration(
                                labelText: 'Institución (Opcional)',
                                hintText: 'Ej. CIMAT, UNAM, Independiente...',
                                prefixIcon: const Icon(Icons.school_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 5. Selector de Rol
                            Text(
                              'Tipo de Cuenta (Rol):',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Selector de roles personalizado y moderno
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _rolSeleccionado = 'observador');
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _rolSeleccionado == 'observador'
                                            ? Colors.green.shade50
                                            : Colors.grey.shade50,
                                        border: Border.all(
                                          color: _rolSeleccionado == 'observador'
                                              ? Colors.green.shade700
                                              : Colors.grey.shade300,
                                          width: _rolSeleccionado == 'observador' ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.remove_red_eye,
                                                size: 18,
                                                color: _rolSeleccionado == 'observador'
                                                    ? Colors.green.shade800
                                                    : Colors.grey.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Observador',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _rolSeleccionado == 'observador'
                                                        ? Colors.green.shade900
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Para registrar y clasificar avistamientos.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _rolSeleccionado = 'admin');
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _rolSeleccionado == 'admin'
                                            ? Colors.amber.shade50
                                            : Colors.grey.shade50,
                                        border: Border.all(
                                          color: _rolSeleccionado == 'admin'
                                              ? Colors.amber.shade700
                                              : Colors.grey.shade300,
                                          width: _rolSeleccionado == 'admin' ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.shield,
                                                size: 18,
                                                color: _rolSeleccionado == 'admin'
                                                    ? Colors.amber.shade900
                                                    : Colors.grey.shade700,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Admin',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _rolSeleccionado == 'admin'
                                                        ? Colors.amber.shade900
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Gestión, moderación y control total.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 6. Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_mostrarPassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña *',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _mostrarPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _mostrarPassword = !_mostrarPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Por favor ingresa una contraseña';
                                }
                                if (val.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 7. Confirmar Contraseña
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_mostrarPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirmar Contraseña *',
                                prefixIcon: const Icon(Icons.lock_reset),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Nota de fecha de registro automática
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'La fecha de registro será asignada automáticamente por el sistema.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Botón de Registrarse
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _registrarse,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _cargando
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Crear Cuenta',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Enlace a Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes una cuenta? ',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
