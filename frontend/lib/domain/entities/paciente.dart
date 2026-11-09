class Paciente {
  const Paciente({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.nutricionistaId,
    required this.peso,
    required this.altura,
    required this.grasaCorporal,
    required this.alergias,
    required this.enfermedades,
    required this.edad,
    required this.sexo,
    required this.factorActividad,
    required this.telefono,
    required this.notas,
    this.motivoConsulta = '',
    this.antecedentesFamiliares = '',
    this.historialMedico = '',
    this.medicamentos = '',
    this.habitosAlimenticios = '',
    this.consumoAgua = '',
    this.actividadFisica = '',
    this.objetivos = '',
    this.notasPrivadas = '',
    this.cintura = 0,
    this.cadera = 0,
    this.brazo = 0,
    this.plieguesCutaneos = '',
    this.porcentajeMusculo = 0,
    this.autorizacionEstado = 'PENDIENTE',
    this.autorizacionFecha = '',
    this.autorizacionFirma = '',
  });

  final int id;
  final String nombre;
  final String correo;
  final int nutricionistaId;
  final double peso;
  final double altura;
  final double grasaCorporal;
  final String alergias;
  final String enfermedades;
  final int edad;
  final String sexo;
  final double factorActividad;
  final String telefono;
  final String notas;
  final String motivoConsulta;
  final String antecedentesFamiliares;
  final String historialMedico;
  final String medicamentos;
  final String habitosAlimenticios;
  final String consumoAgua;
  final String actividadFisica;
  final String objetivos;
  final String notasPrivadas;
  final double cintura;
  final double cadera;
  final double brazo;
  final String plieguesCutaneos;
  final double porcentajeMusculo;
  final String autorizacionEstado;
  final String autorizacionFecha;
  final String autorizacionFirma;

  Paciente copyWith({
    int? id,
    String? nombre,
    String? correo,
    int? nutricionistaId,
    double? peso,
    double? altura,
    double? grasaCorporal,
    String? alergias,
    String? enfermedades,
    int? edad,
    String? sexo,
    double? factorActividad,
    String? telefono,
    String? notas,
    String? motivoConsulta,
    String? antecedentesFamiliares,
    String? historialMedico,
    String? medicamentos,
    String? habitosAlimenticios,
    String? consumoAgua,
    String? actividadFisica,
    String? objetivos,
    String? notasPrivadas,
    double? cintura,
    double? cadera,
    double? brazo,
    String? plieguesCutaneos,
    double? porcentajeMusculo,
    String? autorizacionEstado,
    String? autorizacionFecha,
    String? autorizacionFirma,
  }) {
    return Paciente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      nutricionistaId: nutricionistaId ?? this.nutricionistaId,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
      grasaCorporal: grasaCorporal ?? this.grasaCorporal,
      alergias: alergias ?? this.alergias,
      enfermedades: enfermedades ?? this.enfermedades,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      factorActividad: factorActividad ?? this.factorActividad,
      telefono: telefono ?? this.telefono,
      notas: notas ?? this.notas,
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      antecedentesFamiliares:
          antecedentesFamiliares ?? this.antecedentesFamiliares,
      historialMedico: historialMedico ?? this.historialMedico,
      medicamentos: medicamentos ?? this.medicamentos,
      habitosAlimenticios: habitosAlimenticios ?? this.habitosAlimenticios,
      consumoAgua: consumoAgua ?? this.consumoAgua,
      actividadFisica: actividadFisica ?? this.actividadFisica,
      objetivos: objetivos ?? this.objetivos,
      notasPrivadas: notasPrivadas ?? this.notasPrivadas,
      cintura: cintura ?? this.cintura,
      cadera: cadera ?? this.cadera,
      brazo: brazo ?? this.brazo,
      plieguesCutaneos: plieguesCutaneos ?? this.plieguesCutaneos,
      porcentajeMusculo: porcentajeMusculo ?? this.porcentajeMusculo,
      autorizacionEstado: autorizacionEstado ?? this.autorizacionEstado,
      autorizacionFecha: autorizacionFecha ?? this.autorizacionFecha,
      autorizacionFirma: autorizacionFirma ?? this.autorizacionFirma,
    );
  }
}
