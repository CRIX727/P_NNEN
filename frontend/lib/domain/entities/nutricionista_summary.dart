class NutricionistaSummary {
  const NutricionistaSummary({
    required this.totalPacientes,
    required this.totalEvaluaciones,
    required this.totalPlanes,
    required this.totalCitas,
    required this.totalMensajes,
    required this.pagosPendientes,
    required this.imcPromedio,
  });

  final int totalPacientes;
  final int totalEvaluaciones;
  final int totalPlanes;
  final int totalCitas;
  final int totalMensajes;
  final int pagosPendientes;
  final double imcPromedio;
}

