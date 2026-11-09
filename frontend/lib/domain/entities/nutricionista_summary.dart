class NutricionistaSummary {
  const NutricionistaSummary({
    required this.totalPacientes,
    required this.totalEvaluaciones,
    required this.totalPlanes,
    required this.totalCitas,
    required this.totalMensajes,
    required this.pagosPendientes,
    required this.imcPromedio,
    this.pacientesNuevos = 0,
    this.pacientesEnRiesgo = 0,
    this.citasProximas = 0,
  });

  final int totalPacientes;
  final int totalEvaluaciones;
  final int totalPlanes;
  final int totalCitas;
  final int totalMensajes;
  final int pagosPendientes;
  final double imcPromedio;
  final int pacientesNuevos;
  final int pacientesEnRiesgo;
  final int citasProximas;
}
