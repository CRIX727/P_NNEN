class PlanAlimenticio {
  const PlanAlimenticio({
    required this.id,
    required this.pacienteId,
    required this.titulo,
    required this.descripcion,
    required this.objetivo,
    required this.condicion,
    required this.plantillaNombre,
    required this.fechaInicio,
    required this.fechaFin,
  });

  final int id;
  final int pacienteId;
  final String titulo;
  final String descripcion;
  final String objetivo;
  final String condicion;
  final String plantillaNombre;
  final String fechaInicio;
  final String fechaFin;
}
