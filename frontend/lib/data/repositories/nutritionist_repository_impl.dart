import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/nutricionista_summary.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/plantilla_plan.dart';
import '../remote/nutritionist_api.dart';
import 'nutritionist_repository.dart';

class NutritionistRepositoryImpl implements NutritionistRepository {
  NutritionistRepositoryImpl(this._api);

  final NutritionistApi _api;

  @override
  Future<NutricionistaSummary> getDashboard() async {
    return (await _api.getDashboard()).toEntity();
  }

  @override
  Future<List<Paciente>> getPatients() async {
    return (await _api.getPatients()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<Paciente> getPatient(int id) async {
    return (await _api.getPatient(id)).toEntity();
  }

  @override
  Future<Paciente> createPatient(Paciente patient) async {
    final dto = await _api.createPatient({
      'nombre': patient.nombre,
      'correo': patient.correo,
      'peso': patient.peso,
      'altura': patient.altura,
      'grasaCorporal': patient.grasaCorporal,
      'alergias': patient.alergias,
      'enfermedades': patient.enfermedades,
      'edad': patient.edad,
      'sexo': patient.sexo,
      'factorActividad': patient.factorActividad,
      'telefono': patient.telefono,
      'notas': patient.notas,
    });
    return dto.toEntity();
  }

  @override
  Future<Paciente> updatePatient(Paciente patient) async {
    final dto = await _api.updatePatient(patient.id, {
      'nombre': patient.nombre,
      'correo': patient.correo,
      'peso': patient.peso,
      'altura': patient.altura,
      'grasaCorporal': patient.grasaCorporal,
      'alergias': patient.alergias,
      'enfermedades': patient.enfermedades,
      'edad': patient.edad,
      'sexo': patient.sexo,
      'factorActividad': patient.factorActividad,
      'telefono': patient.telefono,
      'notas': patient.notas,
    });
    return dto.toEntity();
  }

  @override
  Future<List<Evaluacion>> getEvaluations(int patientId) async {
    return (await _api.getEvaluations(patientId)).map((item) => item.toEntity()).toList();
  }

  @override
  Future<Evaluacion> createEvaluation(
    int patientId,
    double peso,
    double altura,
    double grasa,
    String fecha,
  ) async {
    final dto = await _api.createEvaluation(
      patientId,
      {
        'peso': peso,
        'altura': altura,
        'grasa': grasa,
        'fecha': fecha,
      },
    );
    return dto.toEntity();
  }

  @override
  Future<List<PlanAlimenticio>> getPlans(int patientId) async {
    return (await _api.getPlans(patientId)).map((item) => item.toEntity()).toList();
  }

  @override
  Future<PlanAlimenticio> createPlan(int patientId, PlanAlimenticio plan) async {
    final dto = await _api.createPlan(patientId, {
      'titulo': plan.titulo,
      'descripcion': plan.descripcion,
      'objetivo': plan.objetivo,
      'condicion': plan.condicion,
      'plantillaNombre': plan.plantillaNombre,
      'fechaInicio': plan.fechaInicio,
      'fechaFin': plan.fechaFin,
    });
    return dto.toEntity();
  }

  @override
  Future<List<CitaPaciente>> getAppointments(int patientId) async {
    return (await _api.getAppointments(patientId)).map((item) => item.toEntity()).toList();
  }

  @override
  Future<CitaPaciente> createAppointment(int patientId, CitaPaciente appointment) async {
    final dto = await _api.createAppointment(patientId, {
      'fecha': appointment.fecha,
      'motivo': appointment.motivo,
      'estado': _stateToString(appointment.estado),
      'canalRecordatorio': appointment.canalRecordatorio,
    });
    return dto.toEntity();
  }

  @override
  Future<List<MensajePaciente>> getMessages(int patientId) async {
    return (await _api.getMessages(patientId)).map((item) => item.toEntity()).toList();
  }

  @override
  Future<MensajePaciente> createMessage(int patientId, MensajePaciente message) async {
    final dto = await _api.createMessage(patientId, {
      'remitente': message.remitente,
      'contenido': message.contenido,
      'fecha': message.fecha,
    });
    return dto.toEntity();
  }

  @override
  Future<List<PagoPaciente>> getPayments(int patientId) async {
    return (await _api.getPayments(patientId)).map((item) => item.toEntity()).toList();
  }

  @override
  Future<PagoPaciente> createPayment(int patientId, PagoPaciente payment) async {
    final dto = await _api.createPayment(patientId, {
      'monto': payment.monto,
      'concepto': payment.concepto,
      'fecha': payment.fecha,
      'estado': _paymentStateToString(payment.estado),
    });
    return dto.toEntity();
  }

  @override
  Future<List<DocumentoPaciente>> getDocuments(int patientId) async {
    return (await _api.getDocuments(patientId)).map((item) => item.toEntity()).toList();
  }

  @override
  Future<DocumentoPaciente> createDocument(int patientId, DocumentoPaciente document) async {
    final dto = await _api.createDocument(patientId, {
      'nombre': document.nombre,
      'tipo': document.tipo,
      'uri': document.uri,
      'fecha': document.fecha,
    });
    return dto.toEntity();
  }

  @override
  Future<List<PlantillaPlan>> getTemplates() async {
    return (await _api.getTemplates()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<PlantillaPlan> createTemplate(PlantillaPlan template) async {
    final dto = await _api.createTemplate({
      'nombre': template.nombre,
      'objetivo': template.objetivo,
      'condicion': template.condicion,
      'descripcion': template.descripcion,
    });
    return dto.toEntity();
  }

  @override
  Future<NutricionistaSettings> getSettings() async {
    return (await _api.getSettings()).toEntity();
  }

  @override
  Future<NutricionistaSettings> updateSettings(NutricionistaSettings settings) async {
    return (await _api.updateSettings({
      'precioConsulta': settings.precioConsulta,
      'whatsapp': settings.whatsapp,
    })).toEntity();
  }

  String _stateToString(CitaEstado state) {
    return switch (state) {
      CitaEstado.agendada => 'AGENDADA',
      CitaEstado.reprogramada => 'REPROGRAMADA',
      CitaEstado.completada => 'COMPLETADA',
      CitaEstado.cancelada => 'CANCELADA',
    };
  }

  String _paymentStateToString(PagoEstado state) {
    return switch (state) {
      PagoEstado.pendiente => 'PENDIENTE',
      PagoEstado.pagado => 'PAGADO',
    };
  }
}
