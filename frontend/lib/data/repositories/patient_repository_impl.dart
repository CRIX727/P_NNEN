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
  Future<List<Invitacion>> getInvitations() async {
    final items = await _api.getInvitations();
    return items.map((json) {
      final nutritionist = json['nutricionista'] as Map<String, dynamic>? ?? {};
      return Invitacion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        correo: json['correo'] as String? ?? '',
        estado: json['estado'] as String? ?? 'PENDIENTE',
        nutricionistaNombre: nutritionist['nombre'] as String? ?? '',
        nutricionistaCorreo: nutritionist['correo'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<void> acceptInvitation(int id) => _api.acceptInvitation(id);

  @override
  Future<void> rejectInvitation(int id) => _api.rejectInvitation(id);

  @override
  Future<List<Evaluacion>> getEvaluations() async {
    return (await _api.getEvaluations())
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<List<PlanAlimenticio>> getPlans() async {
    return (await _api.getPlans()).map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<CitaPaciente>> getAppointments() async {
    return (await _api.getAppointments())
        .map((item) => item.toEntity())
        .toList();
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

  @override
  Future<List<Notificacion>> getNotifications() async {
    final items = await _api.getNotifications();
    return items
        .map((json) => Notificacion(
              id: (json['id'] as num?)?.toInt() ?? 0,
              tipo: json['tipo'] as String? ?? '',
              titulo: json['titulo'] as String? ?? '',
              contenido: json['contenido'] as String? ?? '',
              leida: json['leida'] as bool? ?? false,
              creadaEn: json['createdAt'] as String? ?? '',
            ))
        .toList();
  }

  @override
  Future<List<Consulta>> getConsultations() async {
    final items = await _api.getConsultations();
    return items
        .map((json) => Consulta(
              id: (json['id'] as num?)?.toInt() ?? 0,
              pacienteId: (json['pacienteId'] as num?)?.toInt() ?? 0,
              fecha: json['fecha'] as String? ?? '',
              motivo: json['motivo'] as String? ?? '',
              notas: json['notas'] as String? ?? '',
              estado: json['estado'] as String? ?? 'REALIZADA',
            ))
        .toList();
  }

  @override
  Future<void> markNotificationRead(int id) => _api.markNotificationRead(id);

  @override
  Future<void> markAllNotificationsRead() => _api.markAllNotificationsRead();

  Suscripcion _subscriptionFromJson(Map<String, dynamic> json) => Suscripcion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        plan: json['plan'] as String? ?? '',
        estado: json['estado'] as String? ?? '',
        periodoInicio: json['periodoInicio'] as String? ?? '',
        periodoFin: json['periodoFin'] as String?,
      );

  @override
  Future<Suscripcion?> getSubscription() async {
    final json = await _api.getSubscription();
    return json == null ? null : _subscriptionFromJson(json);
  }

  @override
  Future<Suscripcion> createSubscription(String plan) async {
    return _subscriptionFromJson(await _api.createSubscription(plan));
  }

  @override
  Future<void> cancelSubscription() => _api.cancelSubscription();
}
