import 'dart:async';

import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/invitacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/paciente_profile.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/entities/consulta.dart';
import '../../domain/entities/suscripcion.dart';
import '../dto/nutritionist_dtos.dart';
import '../local/local_database.dart';
import '../sync/sync_manager.dart';
import 'patient_repository.dart';

class OfflinePatientRepository implements PatientRepository {
  OfflinePatientRepository({
    required PatientRepository remote,
    required LocalDatabase database,
    required SyncManager sync,
    required String ownerKey,
  })  : _remote = remote,
        _database = database,
        _sync = sync,
        _ownerKey = ownerKey {
    _sync.registerDownloader(_ownerKey, _refreshFromRemote);
  }

  final PatientRepository _remote;
  final LocalDatabase _database;
  final SyncManager _sync;
  final String _ownerKey;

  Future<void> dispose() async => _sync.unregisterDownloader(_ownerKey);

  Future<void> _refreshFromRemote() async {
    final profile = await _remote.getProfile();
    await _cache('profile', profile.paciente.id, _profileJson(profile));
    final results = await Future.wait([
      _remote.getEvaluations(),
      _remote.getPlans(),
      _remote.getAppointments(),
      _remote.getMessages(),
      _remote.getPayments(),
      _remote.getDocuments(),
      _remote.getConsultations(),
      _remote.getNotifications(),
      _remote.getSubscription(),
    ]);
    for (final item in results[0] as List<Evaluacion>) {
      await _cache('patient-evaluation', item.id, _evaluationJson(item));
    }
    for (final item in results[1] as List<PlanAlimenticio>) {
      await _cache('patient-plan', item.id, _planJson(item));
    }
    for (final item in results[2] as List<CitaPaciente>) {
      await _cache('patient-appointment', item.id, _appointmentJson(item));
    }
    for (final item in results[3] as List<MensajePaciente>) {
      await _cache('patient-message', item.id, _messageJson(item));
    }
    for (final item in results[4] as List<PagoPaciente>) {
      await _cache('patient-payment', item.id, _paymentJson(item));
    }
    for (final item in results[5] as List<DocumentoPaciente>) {
      await _cache('patient-document', item.id, _documentJson(item));
    }
    for (final item in results[6] as List<Consulta>) {
      await _cache('patient-consultation', item.id, _consultationJson(item));
    }
    for (final item in results[7] as List<Notificacion>) {
      await _cache('patient-notification', item.id, _notificationJson(item));
    }
    final subscription = results[8] as Suscripcion?;
    if (subscription != null) {
      await _cache('patient-subscription', subscription.id,
          _subscriptionJson(subscription));
    }
  }

  Future<void> _cache(String type, int id, Map<String, dynamic> value,
          {bool synced = true}) =>
      _database.cacheRecord(
          type: type,
          remoteId: id,
          ownerKey: _ownerKey,
          value: value,
          isSynced: synced);

  Future<List<Map<String, dynamic>>> _read(String type) =>
      _database.readRecords(type: type, ownerKey: _ownerKey);

  Future<void> _queue(
          String method, String endpoint, Map<String, dynamic> body) =>
      _database.enqueue(
        method: method,
        endpoint: endpoint,
        payload: body,
        ownerKey: _ownerKey,
        recordType: _recordTypeForEndpoint(endpoint),
        remoteId: _remoteIdFromEndpoint(endpoint),
      );

  String _recordTypeForEndpoint(String endpoint) {
    if (endpoint.contains('/evaluaciones')) return 'patient-evaluation';
    if (endpoint.contains('/planes')) return 'patient-plan';
    if (endpoint.contains('/citas')) return 'patient-appointment';
    if (endpoint.contains('/mensajes')) return 'patient-message';
    if (endpoint.contains('/pagos')) return 'patient-payment';
    if (endpoint.contains('/documentos')) return 'patient-document';
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

  @override
  Future<PacienteProfile> getProfile() async {
    final cached = await _read('profile');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      final json = cached.first;
      return PacienteProfile(
        paciente: PatientDto.fromJson(json['paciente'] as Map<String, dynamic>)
            .toEntity(),
        nutricionistaNombre: json['nutricionistaNombre'] as String? ?? '',
        nutricionistaCorreo: json['nutricionistaCorreo'] as String? ?? '',
        nutricionistaWhatsapp: json['nutricionistaWhatsapp'] as String? ?? '',
      );
    }
    try {
      final result = await _remote.getProfile();
      await _cache('profile', result.paciente.id, _profileJson(result));
      return result;
    } catch (_) {
      final rows = await _read('profile');
      if (rows.isEmpty) rethrow;
      final json = rows.first;
      return PacienteProfile(
        paciente: PatientDto.fromJson(json['paciente'] as Map<String, dynamic>)
            .toEntity(),
        nutricionistaNombre: json['nutricionistaNombre'] as String? ?? '',
        nutricionistaCorreo: json['nutricionistaCorreo'] as String? ?? '',
        nutricionistaWhatsapp: json['nutricionistaWhatsapp'] as String? ?? '',
      );
    }
  }

  @override
  Future<List<Invitacion>> getInvitations() => _remote.getInvitations();

  @override
  Future<void> acceptInvitation(int id) => _remote.acceptInvitation(id);

  @override
  Future<void> rejectInvitation(int id) => _remote.rejectInvitation(id);

  @override
  Future<List<Evaluacion>> getEvaluations() async {
    final cached = await _read('patient-evaluation');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached
          .map((json) => EvaluationDto.fromJson(json).toEntity())
          .toList();
    }
    try {
      final items = await _remote.getEvaluations();
      for (final item in items) {
        await _cache('patient-evaluation', item.id, _evaluationJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-evaluation'))
          .map((json) => EvaluationDto.fromJson(json).toEntity())
          .toList();
    }
  }

  @override
  Future<List<PlanAlimenticio>> getPlans() async {
    final cached = await _read('patient-plan');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached.map((json) => PlanDto.fromJson(json).toEntity()).toList();
    }
    try {
      final items = await _remote.getPlans();
      for (final item in items) {
        await _cache('patient-plan', item.id, _planJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-plan'))
          .map((json) => PlanDto.fromJson(json).toEntity())
          .toList();
    }
  }

  @override
  Future<List<CitaPaciente>> getAppointments() async {
    final cached = await _read('patient-appointment');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached
          .map((json) => AppointmentDto.fromJson(json).toEntity())
          .toList();
    }
    try {
      final items = await _remote.getAppointments();
      for (final item in items) {
        await _cache('patient-appointment', item.id, _appointmentJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-appointment'))
          .map((json) => AppointmentDto.fromJson(json).toEntity())
          .toList();
    }
  }

  @override
  Future<List<MensajePaciente>> getMessages() async {
    final cached = await _read('patient-message');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached
          .map((json) => MessageDto.fromJson(json).toEntity())
          .toList();
    }
    try {
      final items = await _remote.getMessages();
      for (final item in items) {
        await _cache('patient-message', item.id, _messageJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-message'))
          .map((json) => MessageDto.fromJson(json).toEntity())
          .toList();
    }
  }

  @override
  Future<MensajePaciente> sendMessage(String content) async {
    try {
      final item = await _remote.sendMessage(content);
      await _cache('patient-message', item.id, _messageJson(item));
      return item;
    } catch (_) {
      final item = MensajePaciente(
          id: -DateTime.now().millisecondsSinceEpoch,
          pacienteId: 0,
          remitente: 'paciente',
          contenido: content,
          fecha: DateTime.now().toIso8601String());
      await _cache('patient-message', item.id, _messageJson(item));
      await _queue('POST', '/paciente/mensajes',
          {'contenido': content, 'fecha': item.fecha});
      return item;
    }
  }

  @override
  Future<List<PagoPaciente>> getPayments() async {
    final cached = await _read('patient-payment');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached
          .map((json) => PaymentDto.fromJson(json).toEntity())
          .toList();
    }
    try {
      final items = await _remote.getPayments();
      for (final item in items) {
        await _cache('patient-payment', item.id, _paymentJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-payment'))
          .map((json) => PaymentDto.fromJson(json).toEntity())
          .toList();
    }
  }

  @override
  Future<List<DocumentoPaciente>> getDocuments() async {
    final cached = await _read('patient-document');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached
          .map((json) => DocumentDto.fromJson(json).toEntity())
          .toList();
    }
    try {
      final items = await _remote.getDocuments();
      for (final item in items) {
        await _cache('patient-document', item.id, _documentJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-document'))
          .map((json) => DocumentDto.fromJson(json).toEntity())
          .toList();
    }
  }

  @override
  Future<List<Notificacion>> getNotifications() async {
    final cached = await _read('patient-notification');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached.map(_notificationFromJson).toList();
    }
    try {
      final items = await _remote.getNotifications();
      for (final item in items) {
        await _cache('patient-notification', item.id, _notificationJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-notification'))
          .map(_notificationFromJson)
          .toList();
    }
  }

  @override
  Future<List<Consulta>> getConsultations() async {
    final cached = await _read('patient-consultation');
    if (cached.isNotEmpty) {
      unawaited(_sync.synchronize());
      return cached.map(_consultationFromJson).toList();
    }
    try {
      final items = await _remote.getConsultations();
      for (final item in items) {
        await _cache('patient-consultation', item.id, _consultationJson(item));
      }
      return items;
    } catch (_) {
      return (await _read('patient-consultation'))
          .map(_consultationFromJson)
          .toList();
    }
  }

  @override
  Future<void> markNotificationRead(int id) => _remote.markNotificationRead(id);

  @override
  Future<void> markAllNotificationsRead() => _remote.markAllNotificationsRead();

  @override
  Future<Suscripcion?> getSubscription() async {
    final cached = await _read('patient-subscription');
    if (cached.isNotEmpty) return _subscriptionFromJson(cached.first);
    try {
      final item = await _remote.getSubscription();
      if (item != null) {
        await _cache('patient-subscription', item.id, _subscriptionJson(item));
      }
      return item;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Suscripcion> createSubscription(String plan) =>
      _remote.createSubscription(plan);

  @override
  Future<void> cancelSubscription() => _remote.cancelSubscription();

  Map<String, dynamic> _notificationJson(Notificacion item) => {
        'id': item.id,
        'tipo': item.tipo,
        'titulo': item.titulo,
        'contenido': item.contenido,
        'leida': item.leida,
        'creadaEn': item.creadaEn,
      };

  Notificacion _notificationFromJson(Map<String, dynamic> json) => Notificacion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        tipo: json['tipo'] as String? ?? '',
        titulo: json['titulo'] as String? ?? '',
        contenido: json['contenido'] as String? ?? '',
        leida: json['leida'] as bool? ?? false,
        creadaEn: json['creadaEn'] as String? ?? '',
      );

  Map<String, dynamic> _consultationJson(Consulta item) => {
        'id': item.id,
        'pacienteId': item.pacienteId,
        'fecha': item.fecha,
        'motivo': item.motivo,
        'notas': item.notas,
        'estado': item.estado,
      };

  Consulta _consultationFromJson(Map<String, dynamic> json) => Consulta(
        id: (json['id'] as num?)?.toInt() ?? 0,
        pacienteId: (json['pacienteId'] as num?)?.toInt() ?? 0,
        fecha: json['fecha'] as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        notas: json['notas'] as String? ?? '',
        estado: json['estado'] as String? ?? 'REALIZADA',
      );

  Map<String, dynamic> _subscriptionJson(Suscripcion item) => {
        'id': item.id,
        'plan': item.plan,
        'estado': item.estado,
        'periodoInicio': item.periodoInicio,
        'periodoFin': item.periodoFin,
      };

  Suscripcion _subscriptionFromJson(Map<String, dynamic> json) => Suscripcion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        plan: json['plan'] as String? ?? '',
        estado: json['estado'] as String? ?? '',
        periodoInicio: json['periodoInicio'] as String? ?? '',
        periodoFin: json['periodoFin'] as String?,
      );

  Map<String, dynamic> _profileJson(PacienteProfile value) => {
        'paciente': _patientJson(value.paciente),
        'nutricionistaNombre': value.nutricionistaNombre,
        'nutricionistaCorreo': value.nutricionistaCorreo,
        'nutricionistaWhatsapp': value.nutricionistaWhatsapp,
      };

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
      };

  Map<String, dynamic> _evaluationJson(Evaluacion e) => {
        'id': e.id,
        'pacienteId': e.pacienteId,
        'peso': e.peso,
        'altura': e.altura,
        'imc': e.imc,
        'tmb': e.tmb,
        'get': e.get,
        'grasa': e.grasa,
        'cintura': e.cintura,
        'cadera': e.cadera,
        'brazo': e.brazo,
        'plieguesCutaneos': e.plieguesCutaneos,
        'porcentajeMusculo': e.porcentajeMusculo,
        'fecha': e.fecha
      };
  Map<String, dynamic> _planJson(PlanAlimenticio p) => {
        'id': p.id,
        'pacienteId': p.pacienteId,
        'titulo': p.titulo,
        'descripcion': p.descripcion,
        'objetivo': p.objetivo,
        'condicion': p.condicion,
        'plantillaNombre': p.plantillaNombre,
        'fechaInicio': p.fechaInicio,
        'fechaFin': p.fechaFin,
        'comidas': p.comidas,
        'sustituciones': p.sustituciones,
        'calorias': p.calorias,
        'proteinas': p.proteinas,
        'carbohidratos': p.carbohidratos,
        'grasasMacros': p.grasasMacros
      };
  Map<String, dynamic> _appointmentJson(CitaPaciente c) => {
        'id': c.id,
        'pacienteId': c.pacienteId,
        'fecha': c.fecha,
        'motivo': c.motivo,
        'estado': c.estado.name.toUpperCase(),
        'canalRecordatorio': c.canalRecordatorio,
        'asistencia': c.asistencia,
        'notas': c.notas
      };
  Map<String, dynamic> _messageJson(MensajePaciente m) => {
        'id': m.id,
        'pacienteId': m.pacienteId,
        'remitente': m.remitente,
        'contenido': m.contenido,
        'fecha': m.fecha
      };
  Map<String, dynamic> _paymentJson(PagoPaciente p) => {
        'id': p.id,
        'pacienteId': p.pacienteId,
        'monto': p.monto,
        'concepto': p.concepto,
        'fecha': p.fecha,
        'estado': p.estado.name.toUpperCase()
      };
  Map<String, dynamic> _documentJson(DocumentoPaciente d) => {
        'id': d.id,
        'pacienteId': d.pacienteId,
        'nombre': d.nombre,
        'tipo': d.tipo,
        'uri': d.uri,
        'fecha': d.fecha
      };
}
