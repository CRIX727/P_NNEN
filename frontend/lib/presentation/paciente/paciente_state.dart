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

enum PacienteSection {
  resumen,
  perfil,
  planes,
  progreso,
  citas,
  comunicacion,
  historial,
  pagos,
  configuracion,
}

class PacienteState {
  const PacienteState({
    required this.section,
    this.profile,
    this.invitations = const [],
    this.evaluaciones = const [],
    this.planes = const [],
    this.citas = const [],
    this.mensajes = const [],
    this.pagos = const [],
    this.documentos = const [],
    this.notificaciones = const [],
    this.consultas = const [],
    this.suscripcion,
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.message,
  });

  const PacienteState.initial() : this(section: PacienteSection.resumen);

  final PacienteSection section;
  final PacienteProfile? profile;
  final List<Invitacion> invitations;
  final List<Evaluacion> evaluaciones;
  final List<PlanAlimenticio> planes;
  final List<CitaPaciente> citas;
  final List<MensajePaciente> mensajes;
  final List<PagoPaciente> pagos;
  final List<DocumentoPaciente> documentos;
  final List<Notificacion> notificaciones;
  final List<Consulta> consultas;
  final Suscripcion? suscripcion;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final String? message;

  int get unreadMessages => mensajes
      .where((item) => item.remitente != 'paciente' && !item.leido)
      .length;

  PacienteState copyWith({
    PacienteSection? section,
    PacienteProfile? profile,
    List<Invitacion>? invitations,
    List<Evaluacion>? evaluaciones,
    List<PlanAlimenticio>? planes,
    List<CitaPaciente>? citas,
    List<MensajePaciente>? mensajes,
    List<PagoPaciente>? pagos,
    List<DocumentoPaciente>? documentos,
    List<Notificacion>? notificaciones,
    List<Consulta>? consultas,
    Suscripcion? suscripcion,
    bool? isLoading,
    bool? isSending,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return PacienteState(
      section: section ?? this.section,
      profile: profile ?? this.profile,
      invitations: invitations ?? this.invitations,
      evaluaciones: evaluaciones ?? this.evaluaciones,
      planes: planes ?? this.planes,
      citas: citas ?? this.citas,
      mensajes: mensajes ?? this.mensajes,
      pagos: pagos ?? this.pagos,
      documentos: documentos ?? this.documentos,
      notificaciones: notificaciones ?? this.notificaciones,
      consultas: consultas ?? this.consultas,
      suscripcion: suscripcion ?? this.suscripcion,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
