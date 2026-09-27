import 'paciente.dart';

class PacienteProfile {
  const PacienteProfile({
    required this.paciente,
    required this.nutricionistaNombre,
    required this.nutricionistaCorreo,
    required this.nutricionistaWhatsapp,
  });

  final Paciente paciente;
  final String nutricionistaNombre;
  final String nutricionistaCorreo;
  final String nutricionistaWhatsapp;
}
