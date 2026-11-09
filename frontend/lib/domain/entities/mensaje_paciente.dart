class MensajePaciente {
  const MensajePaciente({
    required this.id,
    required this.pacienteId,
    required this.remitente,
    required this.contenido,
    required this.fecha,
    this.leido = false,
  });

  final int id;
  final int pacienteId;
  final String remitente;
  final String contenido;
  final String fecha;
  final bool leido;
}
