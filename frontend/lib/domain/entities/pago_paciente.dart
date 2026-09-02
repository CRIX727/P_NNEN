enum PagoEstado {
  pendiente,
  pagado,
}

class PagoPaciente {
  const PagoPaciente({
    required this.id,
    required this.pacienteId,
    required this.monto,
    required this.concepto,
    required this.fecha,
    required this.estado,
  });

  final int id;
  final int pacienteId;
  final double monto;
  final String concepto;
  final String fecha;
  final PagoEstado estado;
}

