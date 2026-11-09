import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/paciente_profile.dart';
import '../../domain/entities/invitacion.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/entities/consulta.dart';
import '../../domain/entities/suscripcion.dart';

abstract interface class PatientRepository {
  Future<PacienteProfile> getProfile();
  Future<List<Invitacion>> getInvitations();
  Future<void> acceptInvitation(int id);
  Future<void> rejectInvitation(int id);

  Future<List<Evaluacion>> getEvaluations();

  Future<List<PlanAlimenticio>> getPlans();

  Future<List<CitaPaciente>> getAppointments();

  Future<List<MensajePaciente>> getMessages();

  Future<MensajePaciente> sendMessage(String content);

  Future<List<PagoPaciente>> getPayments();

  Future<List<DocumentoPaciente>> getDocuments();
  Future<List<Consulta>> getConsultations();
  Future<Suscripcion?> getSubscription();
  Future<Suscripcion> createSubscription(String plan);
  Future<void> cancelSubscription();
  Future<List<Notificacion>> getNotifications();
  Future<void> markNotificationRead(int id);
  Future<void> markAllNotificationsRead();
}
