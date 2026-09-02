import 'user_role.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  final int id;
  final String nombre;
  final String correo;
  final UserRole rol;
}

