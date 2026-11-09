class Evaluacion {
  const Evaluacion({
    required this.id,
    required this.pacienteId,
    required this.peso,
    required this.altura,
    required this.imc,
    required this.tmb,
    required this.get,
    required this.grasa,
    required this.fecha,
    this.cintura = 0,
    this.cadera = 0,
    this.brazo = 0,
    this.plieguesCutaneos = '',
    this.porcentajeMusculo = 0,
  });

  final int id;
  final int pacienteId;
  final double peso;
  final double altura;
  final double imc;
  final double tmb;
  final double get;
  final double grasa;
  final String fecha;
  final double cintura;
  final double cadera;
  final double brazo;
  final String plieguesCutaneos;
  final double porcentajeMusculo;
}
