class UsuarioModel {
  final int id;
  final String email;
  final String username;
  final String nombre;
  final String apellidos;
  final String institucion;
  final String rol;
  final DateTime? fechaRegistro;
  final bool isStaff;

  UsuarioModel({
    required this.id,
    required this.email,
    required this.username,
    required this.nombre,
    required this.apellidos,
    this.institucion = '',
    this.rol = 'observador',
    this.fechaRegistro,
    this.isStaff = false,
  });

  bool get esAdmin => rol.toLowerCase() == 'admin' || isStaff;

  String get nombreCompleto => '$nombre $apellidos'.trim();

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    DateTime? fecha;
    if (json['fecha_registro'] != null) {
      try {
        fecha = DateTime.parse(json['fecha_registro'].toString()).toLocal();
      } catch (_) {}
    }

    return UsuarioModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      institucion: json['institucion']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'observador',
      fechaRegistro: fecha,
      isStaff: json['is_staff'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'nombre': nombre,
      'apellidos': apellidos,
      'institucion': institucion,
      'rol': rol,
      'fecha_registro': fechaRegistro?.toIso8601String(),
      'is_staff': isStaff,
    };
  }
}
