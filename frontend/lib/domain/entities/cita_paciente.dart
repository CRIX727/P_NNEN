enum CitaEstado {
  agendada,
  reprogramada,
  completada,
  cancelada,
}

class CitaPaciente {
  const CitaPaciente({
    required this.id,
    required this.pacienteId,
    required this.fecha,
    required this.motivo,
    required this.estado,
    required this.canalRecordatorio,
  });

  final int id;
  final int pacienteId;
  final String fecha;
  final String motivo;
  final CitaEstado estado;
  final String canalRecordatorio;
}

