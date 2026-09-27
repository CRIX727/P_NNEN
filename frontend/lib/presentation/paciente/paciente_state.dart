import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/paciente_profile.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';

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
    this.evaluaciones = const [],
    this.planes = const [],
    this.citas = const [],
    this.mensajes = const [],
    this.pagos = const [],
    this.documentos = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.message,
  });

  const PacienteState.initial() : this(section: PacienteSection.resumen);

  final PacienteSection section;
  final PacienteProfile? profile;
  final List<Evaluacion> evaluaciones;
  final List<PlanAlimenticio> planes;
  final List<CitaPaciente> citas;
  final List<MensajePaciente> mensajes;
  final List<PagoPaciente> pagos;
  final List<DocumentoPaciente> documentos;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final String? message;

  PacienteState copyWith({
    PacienteSection? section,
    PacienteProfile? profile,
    List<Evaluacion>? evaluaciones,
    List<PlanAlimenticio>? planes,
    List<CitaPaciente>? citas,
    List<MensajePaciente>? mensajes,
    List<PagoPaciente>? pagos,
    List<DocumentoPaciente>? documentos,
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
      evaluaciones: evaluaciones ?? this.evaluaciones,
      planes: planes ?? this.planes,
      citas: citas ?? this.citas,
      mensajes: mensajes ?? this.mensajes,
      pagos: pagos ?? this.pagos,
      documentos: documentos ?? this.documentos,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
