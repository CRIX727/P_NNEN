import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/paciente_profile.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';

abstract interface class PatientRepository {
  Future<PacienteProfile> getProfile();

  Future<List<Evaluacion>> getEvaluations();

  Future<List<PlanAlimenticio>> getPlans();

  Future<List<CitaPaciente>> getAppointments();

  Future<List<MensajePaciente>> getMessages();

  Future<MensajePaciente> sendMessage(String content);

  Future<List<PagoPaciente>> getPayments();

  Future<List<DocumentoPaciente>> getDocuments();
}
