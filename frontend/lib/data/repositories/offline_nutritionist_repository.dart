import 'dart:async';

import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/alimento.dart';
import '../../domain/entities/consulta.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/invitacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/nutricionista_summary.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plantilla_plan.dart';
import '../../domain/entities/tarea_nutricionista.dart';
import '../local/local_database.dart';
import '../dto/nutritionist_dtos.dart';
import '../sync/sync_manager.dart';
import 'nutritionist_repository.dart';
import 'nutritionist_repository_impl.dart';

class OfflineNutritionistRepository implements NutritionistRepository {
  OfflineNutritionistRepository({
    required NutritionistRepositoryImpl remote,
    required LocalDatabase database,
    required SyncManager sync,
    required String ownerKey,
  })  : _remote = remote,
        _database = database,
        _sync = sync,
        _ownerKey = ownerKey {
    _sync.registerDownloader(_ownerKey, _refreshFromRemote);
  }

  final NutritionistRepositoryImpl _remote;
  final LocalDatabase _database;
  final SyncManager _sync;
  final String _ownerKey;

  Future<void> dispose() async => _sync.unregisterDownloader(_ownerKey);

  Future<void> _refreshFromRemote() async {
    final patients = await _remote.getPatients();
    for (final patient in patients) {
      await _cache('patient', patient.id, _patientJson(patient));
      final patientId = patient.id;
      final results = await Future.wait([
        _remote.getEvaluations(patientId),
        _remote.getPlans(patientId),
        _remote.getAppointments(patientId),
        _remote.getMessages(patientId),
        _remote.getPayments(patientId),
        _remote.getDocuments(patientId),
        _remote.getConsultations(patientId),
      ]);
      for (final item in results[0] as List<Evaluacion>) {
        await _cache('evaluation:$patientId', item.id, _evaluationJson(item));
      }
      for (final item in results[1] as List<PlanAlimenticio>) {
        await _cache('plan:$patientId', item.id, _planJson(item));
      }
      for (final item in results[2] as List<CitaPaciente>) {
        await _cache('appointment:$patientId', item.id, _appointmentJson(item));
      }
      for (final item in results[3] as List<MensajePaciente>) {
        await _cache('message:$patientId', item.id, _messageJson(item));
      }
      for (final item in results[4] as List<PagoPaciente>) {
        await _cache('payment:$patientId', item.id, _paymentJson(item));
      }
      for (final item in results[5] as List<DocumentoPaciente>) {
        await _cache('document:$patientId', item.id, _documentJson(item));
      }
      for (final item in results[6] as List<Consulta>) {
        await _cache(
            'consultation:$patientId', item.id, _consultationJson(item));
      }
    }
  }

  Future<void> _syncPending() => _sync.synchronize();

  Future<void> _cache(String type, int id, Map<String, dynamic> value,
      {bool synced = true}) {
    return _database.cacheRecord(
      type: type,
      remoteId: id,
      ownerKey: _ownerKey,
      value: value,
      isSynced: synced,
    );
  }

  Future<void> _queue(
      String method, String endpoint, Map<String, dynamic> value) {
    return _database.enqueue(
      method: method,
      endpoint: endpoint,
      payload: value,
      ownerKey: _ownerKey,
      recordType: _recordTypeForEndpoint(endpoint),
      remoteId: _remoteIdFromEndpoint(endpoint),
    );
  }

  String _recordTypeForEndpoint(String endpoint) {
    if (endpoint.contains('/evaluaciones')) return 'evaluation';
    if (endpoint.contains('/planes')) return 'plan';
    if (endpoint.contains('/citas')) return 'appointment';
    if (endpoint.contains('/mensajes')) return 'message';
    if (endpoint.contains('/pagos')) return 'payment';
    if (endpoint.contains('/documentos')) return 'document';
    if (endpoint.contains('/consultas')) return 'consultation';
    if (endpoint.contains('/tareas')) return 'task';
    if (endpoint.contains('/pacientes')) return 'patient';
    return 'unknown';
  }

  int? _remoteIdFromEndpoint(String endpoint) {
    final ids = RegExp(r'/\d+(?:/|$)')
        .allMatches(endpoint)
        .map((match) => int.tryParse(match.group(0)!.replaceAll('/', '')))
        .whereType<int>()
        .toList();
    return ids.isEmpty ? null : ids.last;
  }

  Map<String, dynamic> _patientJson(Paciente item) => {
        'id': item.id,
        'nombre': item.nombre,
        'correo': item.correo,
        'nutricionistaId': item.nutricionistaId,
        'peso': item.peso,
        'altura': item.altura,
        'grasaCorporal': item.grasaCorporal,
        'alergias': item.alergias,
        'enfermedades': item.enfermedades,
        'edad': item.edad,
        'sexo': item.sexo,
        'factorActividad': item.factorActividad,
        'telefono': item.telefono,
        'notas': item.notas,
        'motivoConsulta': item.motivoConsulta,
        'antecedentesFamiliares': item.antecedentesFamiliares,
        'historialMedico': item.historialMedico,
        'medicamentos': item.medicamentos,
        'habitosAlimenticios': item.habitosAlimenticios,
        'consumoAgua': item.consumoAgua,
        'actividadFisica': item.actividadFisica,
        'objetivos': item.objetivos,
        'notasPrivadas': item.notasPrivadas,
        'cintura': item.cintura,
        'cadera': item.cadera,
        'brazo': item.brazo,
        'plieguesCutaneos': item.plieguesCutaneos,
        'porcentajeMusculo': item.porcentajeMusculo,
        'autorizacionEstado': item.autorizacionEstado,
        'autorizacionFecha': item.autorizacionFecha,
        'autorizacionFirma': item.autorizacionFirma,
      };

  Map<String, dynamic> _evaluationJson(Evaluacion item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        'peso': item.peso,
        'altura': item.altura,
        'imc': item.imc,
        'tmb': item.tmb,
        'get': item.get,
        'grasa': item.grasa,
        'cintura': item.cintura,
        'cadera': item.cadera,
        'brazo': item.brazo,
        'plieguesCutaneos': item.plieguesCutaneos,
        'porcentajeMusculo': item.porcentajeMusculo,
        'fecha': item.fecha,
      };

  Map<String, dynamic> _planJson(PlanAlimenticio item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        'titulo': item.titulo,
        'descripcion': item.descripcion,
        'objetivo': item.objetivo,
        'condicion': item.condicion,
        'plantillaNombre': item.plantillaNombre,
        'fechaInicio': item.fechaInicio,
        'fechaFin': item.fechaFin,
        'comidas': item.comidas,
        'sustituciones': item.sustituciones,
        'calorias': item.calorias,
        'proteinas': item.proteinas,
        'carbohidratos': item.carbohidratos,
        'grasasMacros': item.grasasMacros,
        'periodo': item.periodo,
        'recordatorio24h': item.recordatorio24h,
        'listaCompras': item.listaCompras,
        'recetas': item.recetas,
        'distribucionCalorias': item.distribucionCalorias,
        'aguaRecomendada': item.aguaRecomendada,
      };

  @override
  Future<List<Paciente>> getPatients() async {
    final cached =
        await _database.readRecords(type: 'patient', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_patientFromJson).toList();
    }
    try {
      final items = await _remote.getPatients();
      for (final item in items) {
        await _cache('patient', item.id, _patientJson(item));
      }
      return items;
    } catch (_) {
      final rows =
          await _database.readRecords(type: 'patient', ownerKey: _ownerKey);
      return rows.map((row) => _patientFromJson(row)).toList();
    }
  }

  @override
  Future<Paciente> getPatient(int id) async {
    try {
      final item = await _remote.getPatient(id);
      await _cache('patient', item.id, _patientJson(item));
      return item;
    } catch (_) {
      final rows = await _database.readRecords(
          type: 'patient', ownerKey: _ownerKey, remoteId: id);
      if (rows.isEmpty) rethrow;
      return _patientFromJson(rows.first);
    }
  }

  @override
  Future<Paciente> createPatient(Paciente patient) async {
    try {
      final item = await _remote.createPatient(patient);
      await _cache('patient', item.id, _patientJson(item));
      return item;
    } catch (_) {
      final local =
          patient.copyWith(id: -DateTime.now().millisecondsSinceEpoch);
      final body = _patientJson(local)..remove('id');
      await _cache('patient', local.id, _patientJson(local));
      await _queue('POST', '/nutricionista/pacientes', body);
      return local;
    }
  }

  @override
  Future<Paciente> updatePatient(Paciente patient) async {
    try {
      final item = await _remote.updatePatient(patient);
      await _cache('patient', item.id, _patientJson(item));
      return item;
    } catch (_) {
      final body = _patientJson(patient)..remove('id');
      await _cache('patient', patient.id, _patientJson(patient));
      await _queue('PUT', '/nutricionista/pacientes/${patient.id}', body);
      return patient;
    }
  }

  @override
  Future<List<Evaluacion>> getEvaluations(int patientId) async {
    final cached = await _database.readRecords(
        type: 'evaluation:$patientId', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_evaluationFromJson).toList();
    }
    try {
      final items = await _remote.getEvaluations(patientId);
      for (final item in items) {
        await _cache('evaluation:$patientId', item.id, _evaluationJson(item));
      }
      return items;
    } catch (_) {
      final rows = await _database.readRecords(
          type: 'evaluation:$patientId', ownerKey: _ownerKey);
      return rows.map((row) => _evaluationFromJson(row)).toList();
    }
  }

  @override
  Future<Evaluacion> createEvaluation(
      int patientId, double peso, double altura, double grasa, String fecha,
      {double cintura = 0,
      double cadera = 0,
      double brazo = 0,
      String plieguesCutaneos = '',
      double porcentajeMusculo = 0}) async {
    try {
      final item = await _remote.createEvaluation(
          patientId, peso, altura, grasa, fecha,
          cintura: cintura,
          cadera: cadera,
          brazo: brazo,
          plieguesCutaneos: plieguesCutaneos,
          porcentajeMusculo: porcentajeMusculo);
      await _cache('evaluation:$patientId', item.id, _evaluationJson(item));
      return item;
    } catch (_) {
      final item = Evaluacion(
          id: -DateTime.now().millisecondsSinceEpoch,
          pacienteId: patientId,
          peso: peso,
          altura: altura,
          imc: altura <= 0 ? 0 : peso / (altura * altura),
          tmb: 0,
          get: 0,
          grasa: grasa,
          cintura: cintura,
          cadera: cadera,
          brazo: brazo,
          plieguesCutaneos: plieguesCutaneos,
          porcentajeMusculo: porcentajeMusculo,
          fecha: fecha);
      await _cache('evaluation:$patientId', item.id, _evaluationJson(item));
      final body = _evaluationJson(item)
        ..remove('id')
        ..remove('pacienteId')
        ..remove('imc')
        ..remove('tmb')
        ..remove('get');
      await _queue(
          'POST', '/nutricionista/pacientes/$patientId/evaluaciones', body);
      return item;
    }
  }

  @override
  Future<Evaluacion> updateEvaluation(
      int patientId, Evaluacion evaluation) async {
    try {
      final item = await _remote.updateEvaluation(patientId, evaluation);
      await _cache('evaluation:$patientId', item.id, _evaluationJson(item));
      return item;
    } catch (_) {
      await _cache(
          'evaluation:$patientId', evaluation.id, _evaluationJson(evaluation));
      final body = _evaluationJson(evaluation)
        ..remove('id')
        ..remove('pacienteId')
        ..remove('imc')
        ..remove('tmb')
        ..remove('get');
      await _queue(
          'PUT',
          '/nutricionista/pacientes/$patientId/evaluaciones/${evaluation.id}',
          body);
      return evaluation;
    }
  }

  @override
  Future<List<PlanAlimenticio>> getPlans(int patientId) async {
    final cached = await _database.readRecords(
        type: 'plan:$patientId', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_planFromJson).toList();
    }
    try {
      final items = await _remote.getPlans(patientId);
      for (final item in items) {
        await _cache('plan:$patientId', item.id, _planJson(item));
      }
      return items;
    } catch (_) {
      final rows = await _database.readRecords(
          type: 'plan:$patientId', ownerKey: _ownerKey);
      return rows.map((row) => _planFromJson(row)).toList();
    }
  }

  @override
  Future<PlanAlimenticio> createPlan(
      int patientId, PlanAlimenticio plan) async {
    try {
      final item = await _remote.createPlan(patientId, plan);
      await _cache('plan:$patientId', item.id, _planJson(item));
      return item;
    } catch (_) {
      final local = PlanAlimenticio(
          id: -DateTime.now().millisecondsSinceEpoch,
          pacienteId: patientId,
          titulo: plan.titulo,
          descripcion: plan.descripcion,
          objetivo: plan.objetivo,
          condicion: plan.condicion,
          plantillaNombre: plan.plantillaNombre,
          fechaInicio: plan.fechaInicio,
          fechaFin: plan.fechaFin,
          comidas: plan.comidas,
          sustituciones: plan.sustituciones,
          calorias: plan.calorias,
          proteinas: plan.proteinas,
          carbohidratos: plan.carbohidratos,
          grasasMacros: plan.grasasMacros,
          periodo: plan.periodo,
          recordatorio24h: plan.recordatorio24h,
          listaCompras: plan.listaCompras,
          recetas: plan.recetas,
          distribucionCalorias: plan.distribucionCalorias,
          aguaRecomendada: plan.aguaRecomendada);
      await _cache('plan:$patientId', local.id, _planJson(local));
      final body = _planJson(local)
        ..remove('id')
        ..remove('pacienteId');
      await _queue('POST', '/nutricionista/pacientes/$patientId/planes', body);
      return local;
    }
  }

  @override
  Future<PlanAlimenticio> updatePlan(
      int patientId, PlanAlimenticio plan) async {
    try {
      final item = await _remote.updatePlan(patientId, plan);
      await _cache('plan:$patientId', item.id, _planJson(item));
      return item;
    } catch (_) {
      await _cache('plan:$patientId', plan.id, _planJson(plan));
      final body = _planJson(plan)
        ..remove('id')
        ..remove('pacienteId');
      await _queue(
          'PUT', '/nutricionista/pacientes/$patientId/planes/${plan.id}', body);
      return plan;
    }
  }

  Paciente _patientFromJson(Map<String, dynamic> json) =>
      _remotePatientDto(json).toEntity();
  Evaluacion _evaluationFromJson(Map<String, dynamic> json) =>
      _remoteEvaluationDto(json).toEntity();
  PlanAlimenticio _planFromJson(Map<String, dynamic> json) =>
      _remotePlanDto(json).toEntity();
  dynamic _remotePatientDto(Map<String, dynamic> json) =>
      PatientDto.fromJson(json);
  dynamic _remoteEvaluationDto(Map<String, dynamic> json) =>
      EvaluationDto.fromJson(json);
  dynamic _remotePlanDto(Map<String, dynamic> json) => PlanDto.fromJson(json);

  Map<String, dynamic> _appointmentJson(CitaPaciente item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        ...AppointmentDto(
          id: item.id,
          pacienteId: item.pacienteId,
          fecha: item.fecha,
          motivo: item.motivo,
          estado: item.estado,
          canalRecordatorio: item.canalRecordatorio,
          asistencia: item.asistencia,
          notas: item.notas,
        ).toJson(),
      };

  Map<String, dynamic> _messageJson(MensajePaciente item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        ...MessageDto(
          id: item.id,
          pacienteId: item.pacienteId,
          remitente: item.remitente,
          contenido: item.contenido,
          fecha: item.fecha,
        ).toJson(),
      };

  Map<String, dynamic> _paymentJson(PagoPaciente item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        ...PaymentDto(
          id: item.id,
          pacienteId: item.pacienteId,
          monto: item.monto,
          concepto: item.concepto,
          fecha: item.fecha,
          estado: item.estado,
        ).toJson(),
      };

  Map<String, dynamic> _documentJson(DocumentoPaciente item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        ...DocumentDto(
          id: item.id,
          pacienteId: item.pacienteId,
          nombre: item.nombre,
          tipo: item.tipo,
          uri: item.uri,
          fecha: item.fecha,
        ).toJson(),
      };

  Map<String, dynamic> _consultationJson(Consulta item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        'fecha': item.fecha,
        'motivo': item.motivo,
        'notas': item.notas,
        'estado': item.estado,
      };

  Consulta _consultationFromJson(Map<String, dynamic> json) => Consulta(
        id: (json['id'] as num).toInt(),
        pacienteId: (json['pacienteId'] as num).toInt(),
        fecha: json['fecha'] as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        notas: json['notas'] as String? ?? '',
        estado: json['estado'] as String? ?? 'PENDIENTE',
      );

  CitaPaciente _appointmentFromJson(Map<String, dynamic> json) =>
      AppointmentDto.fromJson(json).toEntity();

  MensajePaciente _messageFromJson(Map<String, dynamic> json) =>
      MessageDto.fromJson(json).toEntity();

  PagoPaciente _paymentFromJson(Map<String, dynamic> json) =>
      PaymentDto.fromJson(json).toEntity();

  DocumentoPaciente _documentFromJson(Map<String, dynamic> json) =>
      DocumentDto.fromJson(json).toEntity();

  @override
  Future<NutricionistaSummary> getDashboard() => _remote.getDashboard();
  @override
  Future<List<Invitacion>> getInvitations() => _remote.getInvitations();
  @override
  Future<void> createInvitation(String correo) =>
      _remote.createInvitation(correo);
  @override
  Future<List<CitaPaciente>> getAppointments(int patientId) async {
    final cached = await _database.readRecords(
        type: 'appointment:$patientId', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_appointmentFromJson).toList();
    }
    try {
      final items = await _remote.getAppointments(patientId);
      for (final item in items) {
        await _cache('appointment:$patientId', item.id, _appointmentJson(item));
      }
      return items;
    } catch (_) {
      final rows = await _database.readRecords(
          type: 'appointment:$patientId', ownerKey: _ownerKey);
      return rows
          .map((row) => AppointmentDto.fromJson(row).toEntity())
          .toList();
    }
  }

  @override
  Future<CitaPaciente> createAppointment(
      int patientId, CitaPaciente appointment) async {
    try {
      final item = await _remote.createAppointment(patientId, appointment);
      await _cache('appointment:$patientId', item.id, _appointmentJson(item));
      return item;
    } catch (_) {
      final local = CitaPaciente(
          id: -DateTime.now().millisecondsSinceEpoch,
          pacienteId: patientId,
          fecha: appointment.fecha,
          motivo: appointment.motivo,
          estado: appointment.estado,
          canalRecordatorio: appointment.canalRecordatorio,
          asistencia: appointment.asistencia,
          notas: appointment.notas);
      await _cache('appointment:$patientId', local.id, _appointmentJson(local));
      final body = _appointmentJson(local)
        ..remove('id')
        ..remove('pacienteId');
      await _queue('POST', '/nutricionista/pacientes/$patientId/citas', body);
      return local;
    }
  }

  @override
  Future<CitaPaciente> updateAppointment(
      int patientId, CitaPaciente appointment) async {
    try {
      final item = await _remote.updateAppointment(patientId, appointment);
      await _cache('appointment:$patientId', item.id, _appointmentJson(item));
      return item;
    } catch (_) {
      await _cache('appointment:$patientId', appointment.id,
          _appointmentJson(appointment));
      final body = _appointmentJson(appointment)
        ..remove('id')
        ..remove('pacienteId');
      await _queue('PUT',
          '/nutricionista/pacientes/$patientId/citas/${appointment.id}', body);
      return appointment;
    }
  }

  @override
  Future<List<MensajePaciente>> getMessages(int patientId) async {
    final cached = await _database.readRecords(
        type: 'message:$patientId', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_messageFromJson).toList();
    }
    try {
      final items = await _remote.getMessages(patientId);
      for (final item in items) {
        await _cache('message:$patientId', item.id, _messageJson(item));
      }
      return items;
    } catch (_) {
      final rows = await _database.readRecords(
          type: 'message:$patientId', ownerKey: _ownerKey);
      return rows.map((row) => MessageDto.fromJson(row).toEntity()).toList();
    }
  }

  @override
  Future<MensajePaciente> createMessage(
      int patientId, MensajePaciente message) async {
    try {
      final item = await _remote.createMessage(patientId, message);
      await _cache('message:$patientId', item.id, _messageJson(item));
      return item;
    } catch (_) {
      final local = MensajePaciente(
          id: -DateTime.now().millisecondsSinceEpoch,
          pacienteId: patientId,
          remitente: message.remitente,
          contenido: message.contenido,
          fecha: message.fecha);
      await _cache('message:$patientId', local.id, _messageJson(local));
      final body = _messageJson(local)
        ..remove('id')
        ..remove('pacienteId');
      await _queue(
          'POST', '/nutricionista/pacientes/$patientId/mensajes', body);
      return local;
    }
  }

  @override
  Future<List<PagoPaciente>> getPayments(int patientId) async {
    final cached = await _database.readRecords(
        type: 'payment:$patientId', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_paymentFromJson).toList();
    }
    try {
      final items = await _remote.getPayments(patientId);
      for (final item in items) {
        await _cache('payment:$patientId', item.id, _paymentJson(item));
      }
      return items;
    } catch (_) {
      final rows = await _database.readRecords(
          type: 'payment:$patientId', ownerKey: _ownerKey);
      return rows.map((row) => PaymentDto.fromJson(row).toEntity()).toList();
    }
  }

  @override
  Future<PagoPaciente> createPayment(
      int patientId, PagoPaciente payment) async {
    try {
      final item = await _remote.createPayment(patientId, payment);
      await _cache('payment:$patientId', item.id, _paymentJson(item));
      return item;
    } catch (_) {
      final local = PagoPaciente(
          id: -DateTime.now().millisecondsSinceEpoch,
          pacienteId: patientId,
          monto: payment.monto,
          concepto: payment.concepto,
          fecha: payment.fecha,
          estado: payment.estado);
      await _cache('payment:$patientId', local.id, _paymentJson(local));
      final body = _paymentJson(local)
        ..remove('id')
        ..remove('pacienteId');
      await _queue('POST', '/nutricionista/pacientes/$patientId/pagos', body);
      return local;
    }
  }

  @override
  Future<PagoPaciente> updatePayment(
      int patientId, PagoPaciente payment) async {
    try {
      final item = await _remote.updatePayment(patientId, payment);
      await _cache('payment:$patientId', item.id, _paymentJson(item));
      return item;
    } catch (_) {
      await _cache('payment:$patientId', payment.id, _paymentJson(payment));
      final body = _paymentJson(payment)
        ..remove('id')
        ..remove('pacienteId');
      await _queue('PUT',
          '/nutricionista/pacientes/$patientId/pagos/${payment.id}', body);
      return payment;
    }
  }

  @override
  Future<List<DocumentoPaciente>> getDocuments(int patientId) async {
    final cached = await _database.readRecords(
        type: 'document:$patientId', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_documentFromJson).toList();
    }
    try {
      final items = await _remote.getDocuments(patientId);
      for (final item in items) {
        await _cache('document:$patientId', item.id, _documentJson(item));
      }
      return items;
    } catch (_) {
      final rows = await _database.readRecords(
          type: 'document:$patientId', ownerKey: _ownerKey);
      return rows.map((row) => DocumentDto.fromJson(row).toEntity()).toList();
    }
  }

  @override
  Future<DocumentoPaciente> createDocument(
      int patientId, DocumentoPaciente document) async {
    try {
      final item = await _remote.createDocument(patientId, document);
      await _cache('document:$patientId', item.id, _documentJson(item));
      return item;
    } catch (_) {
      final local = DocumentoPaciente(
          id: -DateTime.now().millisecondsSinceEpoch,
          pacienteId: patientId,
          nombre: document.nombre,
          tipo: document.tipo,
          uri: document.uri,
          fecha: document.fecha);
      await _cache('document:$patientId', local.id, _documentJson(local));
      final body = _documentJson(local)
        ..remove('id')
        ..remove('pacienteId');
      await _queue(
          'POST', '/nutricionista/pacientes/$patientId/documentos', body);
      return local;
    }
  }

  @override
  Future<DocumentoPaciente> uploadDocument(int patientId, String filePath,
      {String? nombre}) async {
    try {
      final item =
          await _remote.uploadDocument(patientId, filePath, nombre: nombre);
      await _cache('document:$patientId', item.id, _documentJson(item));
      return item;
    } catch (_) {
      final fallback = DocumentoPaciente(
        id: -DateTime.now().millisecondsSinceEpoch,
        pacienteId: patientId,
        nombre: nombre ?? filePath.split(RegExp(r'[\\/]')).last,
        tipo: 'Documento local',
        uri: filePath,
        fecha: DateTime.now().toIso8601String(),
      );
      await _cache('document:$patientId', fallback.id, _documentJson(fallback));
      final body = _documentJson(fallback)
        ..remove('id')
        ..remove('pacienteId');
      await _queue(
          'POST', '/nutricionista/pacientes/$patientId/documentos', body);
      return fallback;
    }
  }

  @override
  Future<List<PlantillaPlan>> getTemplates() => _remote.getTemplates();
  @override
  Future<PlantillaPlan> createTemplate(PlantillaPlan template) =>
      _remote.createTemplate(template);
  @override
  Future<NutricionistaSettings> getSettings() => _remote.getSettings();
  @override
  Future<NutricionistaSettings> updateSettings(
          NutricionistaSettings settings) =>
      _remote.updateSettings(settings);
  @override
  Future<List<Alimento>> getFoods() => _remote.getFoods();
  @override
  Future<List<TareaNutricionista>> getTasks() async {
    final cached =
        await _database.readRecords(type: 'task', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_taskFromJson).toList();
    }
    try {
      final items = await _remote.getTasks();
      for (final item in items) {
        await _cache('task', item.id, _taskJson(item));
      }
      return items;
    } catch (_) {
      final rows =
          await _database.readRecords(type: 'task', ownerKey: _ownerKey);
      return rows.map(_taskFromJson).toList();
    }
  }

  @override
  Future<TareaNutricionista> createTask(TareaNutricionista task) async {
    try {
      final item = await _remote.createTask(task);
      await _cache('task', item.id, _taskJson(item));
      return item;
    } catch (_) {
      final local = TareaNutricionista(
        id: -DateTime.now().millisecondsSinceEpoch,
        titulo: task.titulo,
        descripcion: task.descripcion,
        fechaLimite: task.fechaLimite,
        completada: task.completada,
        pacienteId: task.pacienteId,
      );
      await _cache('task', local.id, _taskJson(local));
      final body = _taskJson(local)..remove('id');
      await _queue('POST', '/nutricionista/tareas', body);
      return local;
    }
  }

  @override
  Future<TareaNutricionista> updateTask(TareaNutricionista task) async {
    try {
      final item = await _remote.updateTask(task);
      await _cache('task', item.id, _taskJson(item));
      return item;
    } catch (_) {
      await _cache('task', task.id, _taskJson(task));
      final body = _taskJson(task)..remove('id');
      await _queue('PUT', '/nutricionista/tareas/${task.id}', body);
      return task;
    }
  }

  @override
  Future<List<Consulta>> getConsultations(int patientId) async {
    final cached = await _database.readRecords(
        type: 'consultation:$patientId', ownerKey: _ownerKey);
    if (cached.isNotEmpty) {
      unawaited(_syncPending());
      return cached.map(_consultationFromJson).toList();
    }
    try {
      final items = await _remote.getConsultations(patientId);
      for (final item in items) {
        await _cache(
            'consultation:$patientId', item.id, _consultationJson(item));
      }
      return items;
    } catch (_) {
      final rows = await _database.readRecords(
        type: 'consultation:$patientId',
        ownerKey: _ownerKey,
      );
      return rows.map(_consultationFromJson).toList();
    }
  }

  @override
  Future<Consulta> createConsultation(
      int patientId, Consulta consultation) async {
    try {
      final item = await _remote.createConsultation(patientId, consultation);
      await _cache('consultation:$patientId', item.id, _consultationJson(item));
      return item;
    } catch (_) {
      final local = Consulta(
        id: -DateTime.now().millisecondsSinceEpoch,
        pacienteId: patientId,
        fecha: consultation.fecha,
        motivo: consultation.motivo,
        notas: consultation.notas,
        estado: consultation.estado,
      );
      await _cache(
          'consultation:$patientId', local.id, _consultationJson(local));
      final body = _consultationJson(local)
        ..remove('id')
        ..remove('pacienteId');
      await _queue(
        'POST',
        '/nutricionista/pacientes/$patientId/consultas',
        body,
      );
      return local;
    }
  }

  Map<String, dynamic> _taskJson(TareaNutricionista task) => {
        'id': task.id,
        'titulo': task.titulo,
        'descripcion': task.descripcion,
        'fechaLimite': task.fechaLimite,
        'completada': task.completada,
        if (task.pacienteId != null) 'pacienteId': task.pacienteId,
      };

  TareaNutricionista _taskFromJson(Map<String, dynamic> json) =>
      TareaNutricionista(
        id: (json['id'] as num?)?.toInt() ?? 0,
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        fechaLimite: json['fechaLimite'] as String? ?? '',
        completada: json['completada'] as bool? ?? false,
        pacienteId: (json['pacienteId'] as num?)?.toInt(),
      );
}
