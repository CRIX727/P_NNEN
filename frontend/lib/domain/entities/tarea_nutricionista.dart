class TareaNutricionista {
  const TareaNutricionista({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaLimite,
    required this.completada,
    this.pacienteId,
  });

  final int id;
  final String titulo;
  final String descripcion;
  final String fechaLimite;
  final bool completada;
  final int? pacienteId;
}
