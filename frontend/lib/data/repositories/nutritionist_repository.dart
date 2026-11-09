import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/alimento.dart';
import '../../domain/entities/consulta.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/invitacion.dart';
import '../../domain/entities/nutricionista_summary.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/plantilla_plan.dart';
import '../../domain/entities/tarea_nutricionista.dart';

abstract class NutritionistRepository {
  Future<NutricionistaSummary> getDashboard();
  Future<List<Paciente>> getPatients();
  Future<List<Invitacion>> getInvitations();
  Future<void> createInvitation(String correo);
  Future<Paciente> getPatient(int id);
  Future<Paciente> createPatient(Paciente patient);
  Future<Paciente> updatePatient(Paciente patient);
  Future<List<Evaluacion>> getEvaluations(int patientId);
  Future<Evaluacion> createEvaluation(
      int patientId, double peso, double altura, double grasa, String fecha,
      {double cintura,
      double cadera,
      double brazo,
      String plieguesCutaneos,
      double porcentajeMusculo});
  Future<Evaluacion> updateEvaluation(int patientId, Evaluacion evaluation);
  Future<List<PlanAlimenticio>> getPlans(int patientId);
  Future<PlanAlimenticio> createPlan(int patientId, PlanAlimenticio plan);
  Future<PlanAlimenticio> updatePlan(int patientId, PlanAlimenticio plan);
  Future<List<CitaPaciente>> getAppointments(int patientId);
  Future<CitaPaciente> createAppointment(
      int patientId, CitaPaciente appointment);
  Future<CitaPaciente> updateAppointment(
      int patientId, CitaPaciente appointment);
  Future<List<MensajePaciente>> getMessages(int patientId);
  Future<MensajePaciente> createMessage(int patientId, MensajePaciente message);
  Future<List<PagoPaciente>> getPayments(int patientId);
  Future<PagoPaciente> createPayment(int patientId, PagoPaciente payment);
  Future<PagoPaciente> updatePayment(int patientId, PagoPaciente payment);
  Future<List<DocumentoPaciente>> getDocuments(int patientId);
  Future<DocumentoPaciente> createDocument(
      int patientId, DocumentoPaciente document);
  Future<DocumentoPaciente> uploadDocument(int patientId, String filePath,
      {String? nombre});
  Future<List<PlantillaPlan>> getTemplates();
  Future<PlantillaPlan> createTemplate(PlantillaPlan template);
  Future<NutricionistaSettings> getSettings();
  Future<NutricionistaSettings> updateSettings(NutricionistaSettings settings);
  Future<List<Alimento>> getFoods();
  Future<List<TareaNutricionista>> getTasks();
  Future<TareaNutricionista> createTask(TareaNutricionista task);
  Future<TareaNutricionista> updateTask(TareaNutricionista task);
  Future<List<Consulta>> getConsultations(int patientId);
  Future<Consulta> createConsultation(int patientId, Consulta consultation);
}
