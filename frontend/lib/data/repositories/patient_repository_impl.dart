import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/paciente_profile.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../remote/patient_api.dart';
import 'patient_repository.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl(this._api);

  final PatientApi _api;

  @override
  Future<PacienteProfile> getProfile() async {
    final profile = await _api.getProfile();
    return PacienteProfile(
      paciente: profile.patient.toEntity(),
      nutricionistaNombre: profile.nutritionistName,
      nutricionistaCorreo: profile.nutritionistEmail,
      nutricionistaWhatsapp: profile.nutritionistWhatsapp,
    );
  }

  @override
  Future<List<Evaluacion>> getEvaluations() async {
    return (await _api.getEvaluations()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<PlanAlimenticio>> getPlans() async {
    return (await _api.getPlans()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<CitaPaciente>> getAppointments() async {
    return (await _api.getAppointments()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<MensajePaciente>> getMessages() async {
    return (await _api.getMessages()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<MensajePaciente> sendMessage(String content) async {
    return (await _api.sendMessage(content)).toEntity();
  }

  @override
  Future<List<PagoPaciente>> getPayments() async {
    return (await _api.getPayments()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<DocumentoPaciente>> getDocuments() async {
    return (await _api.getDocuments()).map((item) => item.toEntity()).toList();
  }
}
