class Consulta {
  const Consulta({
    required this.id,
    required this.pacienteId,
    required this.fecha,
    required this.motivo,
    required this.notas,
    required this.estado,
  });

  final int id;
  final int pacienteId;
  final String fecha;
  final String motivo;
  final String notas;
  final String estado;
}
