class Invitacion {
  const Invitacion({
    required this.id,
    required this.correo,
    required this.estado,
    required this.nutricionistaNombre,
    required this.nutricionistaCorreo,
  });

  final int id;
  final String correo;
  final String estado;
  final String nutricionistaNombre;
  final String nutricionistaCorreo;
}
