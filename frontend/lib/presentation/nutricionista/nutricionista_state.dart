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

enum NutricionistaSection {
  dashboard,
  agregarPaciente,
  misPacientes,
  planes,
  agenda,
  comunicacion,
  pagos,
  configuracion,
}

class NutricionistaState {
  const NutricionistaState({
    required this.loading,
    required this.section,
    this.message,
    this.summary,
    this.pacientes = const [],
    this.selectedPatient,
    this.evaluations = const [],
    this.plans = const [],
    this.appointments = const [],
    this.messages = const [],
    this.payments = const [],
    this.documents = const [],
    this.templates = const [],
    this.settings,
  });

  const NutricionistaState.initial()
      : loading = false,
        section = NutricionistaSection.dashboard,
        message = null,
        summary = null,
        pacientes = const [],
        selectedPatient = null,
        evaluations = const [],
        plans = const [],
        appointments = const [],
        messages = const [],
        payments = const [],
        documents = const [],
        templates = const [],
        settings = null;

  final bool loading;
  final NutricionistaSection section;
  final String? message;
  final NutricionistaSummary? summary;
  final List<Paciente> pacientes;
  final Paciente? selectedPatient;
  final List<Evaluacion> evaluations;
  final List<PlanAlimenticio> plans;
  final List<CitaPaciente> appointments;
  final List<MensajePaciente> messages;
  final List<PagoPaciente> payments;
  final List<DocumentoPaciente> documents;
  final List<PlantillaPlan> templates;
  final NutricionistaSettings? settings;

  NutricionistaState copyWith({
    bool? loading,
    NutricionistaSection? section,
    String? message,
    bool clearMessage = false,
    NutricionistaSummary? summary,
    List<Paciente>? pacientes,
    Paciente? selectedPatient,
    List<Evaluacion>? evaluations,
    List<PlanAlimenticio>? plans,
    List<CitaPaciente>? appointments,
    List<MensajePaciente>? messages,
    List<PagoPaciente>? payments,
    List<DocumentoPaciente>? documents,
    List<PlantillaPlan>? templates,
    NutricionistaSettings? settings,
  }) {
    return NutricionistaState(
      loading: loading ?? this.loading,
      section: section ?? this.section,
      message: clearMessage ? null : (message ?? this.message),
      summary: summary ?? this.summary,
      pacientes: pacientes ?? this.pacientes,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      evaluations: evaluations ?? this.evaluations,
      plans: plans ?? this.plans,
      appointments: appointments ?? this.appointments,
      messages: messages ?? this.messages,
      payments: payments ?? this.payments,
      documents: documents ?? this.documents,
      templates: templates ?? this.templates,
      settings: settings ?? this.settings,
    );
  }
}

