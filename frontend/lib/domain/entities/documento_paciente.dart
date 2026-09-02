class DocumentoPaciente {
  const DocumentoPaciente({
    required this.id,
    required this.pacienteId,
    required this.nombre,
    required this.tipo,
    required this.uri,
    required this.fecha,
  });

  final int id;
  final int pacienteId;
  final String nombre;
  final String tipo;
  final String uri;
  final String fecha;
}

