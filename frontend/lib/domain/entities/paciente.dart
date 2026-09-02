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
    );
  }
}
