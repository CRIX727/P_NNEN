class Suscripcion {
  const Suscripcion({
    required this.id,
    required this.plan,
    required this.estado,
    required this.periodoInicio,
    this.periodoFin,
  });

  final int id;
  final String plan;
  final String estado;
  final String periodoInicio;
  final String? periodoFin;
}
