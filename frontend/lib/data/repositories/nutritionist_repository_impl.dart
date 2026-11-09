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
import '../remote/nutritionist_api.dart';
import '../dto/nutritionist_dtos.dart';
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
  Future<List<Invitacion>> getInvitations() async {
    final items = await _api.getInvitations();
    return items.map(_invitationFromJson).toList();
  }

  @override
  Future<void> createInvitation(String correo) async {
    await _api.createInvitation(correo);
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
      'motivoConsulta': patient.motivoConsulta,
      'antecedentesFamiliares': patient.antecedentesFamiliares,
      'historialMedico': patient.historialMedico,
      'medicamentos': patient.medicamentos,
      'habitosAlimenticios': patient.habitosAlimenticios,
      'consumoAgua': patient.consumoAgua,
      'actividadFisica': patient.actividadFisica,
      'objetivos': patient.objetivos,
      'notasPrivadas': patient.notasPrivadas,
      'cintura': patient.cintura,
      'cadera': patient.cadera,
      'brazo': patient.brazo,
      'plieguesCutaneos': patient.plieguesCutaneos,
      'porcentajeMusculo': patient.porcentajeMusculo,
      'autorizacionEstado': patient.autorizacionEstado,
      'autorizacionFecha': patient.autorizacionFecha,
      'autorizacionFirma': patient.autorizacionFirma,
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
      'motivoConsulta': patient.motivoConsulta,
      'antecedentesFamiliares': patient.antecedentesFamiliares,
      'historialMedico': patient.historialMedico,
      'medicamentos': patient.medicamentos,
      'habitosAlimenticios': patient.habitosAlimenticios,
      'consumoAgua': patient.consumoAgua,
      'actividadFisica': patient.actividadFisica,
      'objetivos': patient.objetivos,
      'notasPrivadas': patient.notasPrivadas,
      'cintura': patient.cintura,
      'cadera': patient.cadera,
      'brazo': patient.brazo,
      'plieguesCutaneos': patient.plieguesCutaneos,
      'porcentajeMusculo': patient.porcentajeMusculo,
      'autorizacionEstado': patient.autorizacionEstado,
      'autorizacionFecha': patient.autorizacionFecha,
      'autorizacionFirma': patient.autorizacionFirma,
    });
    return dto.toEntity();
  }

  @override
  Future<List<Evaluacion>> getEvaluations(int patientId) async {
    return (await _api.getEvaluations(patientId))
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<Evaluacion> createEvaluation(
    int patientId,
    double peso,
    double altura,
    double grasa,
    String fecha, {
    double cintura = 0,
    double cadera = 0,
    double brazo = 0,
    String plieguesCutaneos = '',
    double porcentajeMusculo = 0,
  }) async {
    final dto = await _api.createEvaluation(
      patientId,
      {
        'peso': peso,
        'altura': altura,
        'grasa': grasa,
        'fecha': fecha,
        'cintura': cintura,
        'cadera': cadera,
        'brazo': brazo,
        'plieguesCutaneos': plieguesCutaneos,
        'porcentajeMusculo': porcentajeMusculo,
      },
    );
    return dto.toEntity();
  }

  @override
  Future<Evaluacion> updateEvaluation(
      int patientId, Evaluacion evaluation) async {
    final dto = await _api.updateEvaluation(
      patientId,
      evaluation.id,
      {
        'peso': evaluation.peso,
        'altura': evaluation.altura,
        'grasa': evaluation.grasa,
        'fecha': evaluation.fecha,
        'cintura': evaluation.cintura,
        'cadera': evaluation.cadera,
        'brazo': evaluation.brazo,
        'plieguesCutaneos': evaluation.plieguesCutaneos,
        'porcentajeMusculo': evaluation.porcentajeMusculo,
      },
    );
    return dto.toEntity();
  }

  @override
  Future<List<PlanAlimenticio>> getPlans(int patientId) async {
    return (await _api.getPlans(patientId))
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<PlanAlimenticio> createPlan(
      int patientId, PlanAlimenticio plan) async {
    final dto = await _api.createPlan(patientId, {
      'titulo': plan.titulo,
      'descripcion': plan.descripcion,
      'objetivo': plan.objetivo,
      'condicion': plan.condicion,
      'plantillaNombre': plan.plantillaNombre,
      'fechaInicio': plan.fechaInicio,
      'fechaFin': plan.fechaFin,
      'comidas': plan.comidas,
      'sustituciones': plan.sustituciones,
      'calorias': plan.calorias,
      'proteinas': plan.proteinas,
      'carbohidratos': plan.carbohidratos,
      'grasasMacros': plan.grasasMacros,
      'periodo': plan.periodo,
      'recordatorio24h': plan.recordatorio24h,
      'listaCompras': plan.listaCompras,
      'recetas': plan.recetas,
      'distribucionCalorias': plan.distribucionCalorias,
      'aguaRecomendada': plan.aguaRecomendada,
    });
    return dto.toEntity();
  }

  @override
  Future<PlanAlimenticio> updatePlan(
      int patientId, PlanAlimenticio plan) async {
    final dto = await _api.updatePlan(patientId, plan.id, _planBody(plan));
    return dto.toEntity();
  }

  @override
  Future<List<CitaPaciente>> getAppointments(int patientId) async {
    return (await _api.getAppointments(patientId))
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<CitaPaciente> createAppointment(
      int patientId, CitaPaciente appointment) async {
    final dto =
        await _api.createAppointment(patientId, _appointmentBody(appointment));
    return dto.toEntity();
  }

  @override
  Future<CitaPaciente> updateAppointment(
      int patientId, CitaPaciente appointment) async {
    final dto = await _api.updateAppointment(
        patientId, appointment.id, _appointmentBody(appointment));
    return dto.toEntity();
  }

  @override
  Future<List<MensajePaciente>> getMessages(int patientId) async {
    return (await _api.getMessages(patientId))
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<MensajePaciente> createMessage(
      int patientId, MensajePaciente message) async {
    final dto = await _api.createMessage(patientId, {
      'remitente': message.remitente,
      'contenido': message.contenido,
      'fecha': message.fecha,
    });
    return dto.toEntity();
  }

  @override
  Future<List<PagoPaciente>> getPayments(int patientId) async {
    return (await _api.getPayments(patientId))
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<PagoPaciente> createPayment(
      int patientId, PagoPaciente payment) async {
    final dto = await _api.createPayment(patientId, _paymentBody(payment));
    return dto.toEntity();
  }

  @override
  Future<PagoPaciente> updatePayment(
      int patientId, PagoPaciente payment) async {
    final dto =
        await _api.updatePayment(patientId, payment.id, _paymentBody(payment));
    return dto.toEntity();
  }

  @override
  Future<List<DocumentoPaciente>> getDocuments(int patientId) async {
    return (await _api.getDocuments(patientId))
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<DocumentoPaciente> createDocument(
      int patientId, DocumentoPaciente document) async {
    final dto = await _api.createDocument(patientId, {
      'nombre': document.nombre,
      'tipo': document.tipo,
      'uri': document.uri,
      'fecha': document.fecha,
    });
    return dto.toEntity();
  }

  @override
  Future<DocumentoPaciente> uploadDocument(int patientId, String filePath,
      {String? nombre}) async {
    final json = await _api.uploadDocument(patientId, filePath, nombre);
    return DocumentDto.fromJson(json).toEntity();
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
  Future<NutricionistaSettings> updateSettings(
      NutricionistaSettings settings) async {
    return (await _api.updateSettings({
      'precioConsulta': settings.precioConsulta,
      'whatsapp': settings.whatsapp,
    }))
        .toEntity();
  }

  @override
  Future<List<Alimento>> getFoods() async {
    final items = await _api.getFoods();
    return items
        .map((json) => Alimento(
              id: (json['id'] as num?)?.toInt() ?? 0,
              nombre: json['nombre'] as String? ?? '',
              porcion: json['porcion'] as String? ?? '',
              calorias: (json['calorias'] as num?)?.toDouble() ?? 0,
              proteinas: (json['proteinas'] as num?)?.toDouble() ?? 0,
              carbohidratos: (json['carbohidratos'] as num?)?.toDouble() ?? 0,
              grasas: (json['grasas'] as num?)?.toDouble() ?? 0,
              fibra: (json['fibra'] as num?)?.toDouble() ?? 0,
              sodio: (json['sodio'] as num?)?.toDouble() ?? 0,
              azucar: (json['azucar'] as num?)?.toDouble() ?? 0,
              micronutrientes: json['micronutrientes'] as String? ?? '',
              sustituciones: json['sustituciones'] as String? ?? '',
              condiciones: json['condiciones'] as String? ?? '',
              favorito: json['favorito'] as bool? ?? false,
              restringido: json['restringido'] as bool? ?? false,
            ))
        .toList();
  }

  @override
  Future<List<TareaNutricionista>> getTasks() async {
    final items = await _api.getTasks();
    return items
        .map((json) => TareaNutricionista(
              id: (json['id'] as num?)?.toInt() ?? 0,
              titulo: json['titulo'] as String? ?? '',
              descripcion: json['descripcion'] as String? ?? '',
              fechaLimite: json['fechaLimite'] as String? ?? '',
              completada: json['completada'] as bool? ?? false,
              pacienteId: (json['pacienteId'] as num?)?.toInt(),
            ))
        .toList();
  }

  @override
  Future<TareaNutricionista> createTask(TareaNutricionista task) async {
    return _taskFromJson(await _api.createTask(_taskBody(task)));
  }

  @override
  Future<TareaNutricionista> updateTask(TareaNutricionista task) async {
    return _taskFromJson(await _api.updateTask(task.id, _taskBody(task)));
  }

  @override
  Future<List<Consulta>> getConsultations(int patientId) async {
    final items = await _api.getConsultations(patientId);
    return items.map(_consultationFromJson).toList();
  }

  @override
  Future<Consulta> createConsultation(
      int patientId, Consulta consultation) async {
    final item = await _api.createConsultation(patientId, {
      'fecha': consultation.fecha,
      'motivo': consultation.motivo,
      'notas': consultation.notas,
      'estado': consultation.estado,
    });
    return _consultationFromJson(item);
  }

  Consulta _consultationFromJson(Map<String, dynamic> json) => Consulta(
        id: (json['id'] as num?)?.toInt() ?? 0,
        pacienteId: (json['pacienteId'] as num?)?.toInt() ?? 0,
        fecha: json['fecha'] as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        notas: json['notas'] as String? ?? '',
        estado: json['estado'] as String? ?? 'REALIZADA',
      );

  TareaNutricionista _taskFromJson(Map<String, dynamic> json) =>
      TareaNutricionista(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        fechaLimite: json['fechaLimite'] as String? ?? '',
        completada: json['completada'] as bool? ?? false,
        pacienteId: (json['pacienteId'] as num?)?.toInt(),
      );

  Map<String, dynamic> _taskBody(TareaNutricionista task) => {
        'titulo': task.titulo,
        'descripcion': task.descripcion,
        'fechaLimite': task.fechaLimite,
        'completada': task.completada,
        if (task.pacienteId != null) 'pacienteId': task.pacienteId,
      };

  String _stateToString(CitaEstado state) {
    return switch (state) {
      CitaEstado.agendada => 'AGENDADA',
      CitaEstado.reprogramada => 'REPROGRAMADA',
      CitaEstado.completada => 'COMPLETADA',
      CitaEstado.cancelada => 'CANCELADA',
    };
  }

  Invitacion _invitationFromJson(Map<String, dynamic> json) {
    final nutritionist = json['nutricionista'] as Map<String, dynamic>? ?? {};
    final patient = json['pacienteUsuario'] as Map<String, dynamic>? ?? {};
    return Invitacion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      correo: json['correo'] as String? ?? patient['correo'] as String? ?? '',
      estado: json['estado'] as String? ?? 'PENDIENTE',
      nutricionistaNombre: nutritionist['nombre'] as String? ?? '',
      nutricionistaCorreo: nutritionist['correo'] as String? ?? '',
    );
  }

  Map<String, dynamic> _planBody(PlanAlimenticio plan) => {
        'titulo': plan.titulo,
        'descripcion': plan.descripcion,
        'objetivo': plan.objetivo,
        'condicion': plan.condicion,
        'plantillaNombre': plan.plantillaNombre,
        'fechaInicio': plan.fechaInicio,
        'fechaFin': plan.fechaFin,
        'comidas': plan.comidas,
        'sustituciones': plan.sustituciones,
        'calorias': plan.calorias,
        'proteinas': plan.proteinas,
        'carbohidratos': plan.carbohidratos,
        'grasasMacros': plan.grasasMacros,
        'periodo': plan.periodo,
        'recordatorio24h': plan.recordatorio24h,
        'listaCompras': plan.listaCompras,
        'recetas': plan.recetas,
        'distribucionCalorias': plan.distribucionCalorias,
        'aguaRecomendada': plan.aguaRecomendada,
      };

  Map<String, dynamic> _appointmentBody(CitaPaciente appointment) => {
        'fecha': appointment.fecha,
        'motivo': appointment.motivo,
        'estado': _stateToString(appointment.estado),
        'canalRecordatorio': appointment.canalRecordatorio,
        'asistencia': appointment.asistencia,
        'notas': appointment.notas,
      };

  Map<String, dynamic> _paymentBody(PagoPaciente payment) => {
        'monto': payment.monto,
        'concepto': payment.concepto,
        'fecha': payment.fecha,
        'estado': _paymentStateToString(payment.estado),
      };

  String _paymentStateToString(PagoEstado state) {
    return switch (state) {
      PagoEstado.pendiente => 'PENDIENTE',
      PagoEstado.pagado => 'PAGADO',
    };
  }
}
