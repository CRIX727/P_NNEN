import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signature/signature.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/services/clinical_report_service.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/consulta.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/plantilla_plan.dart';
import '../../domain/entities/nutricionista_settings.dart';
import 'nutricionista_controller.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({
    super.key,
    required this.patientId,
  });

  final int patientId;

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  final _reportService = ClinicalReportService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionistControllerProvider).selectPatient(widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(nutritionistControllerProvider);
    final state = controller.state;
    final patient = state.selectedPatient;

    if (patient == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(patient.nombre),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/nutricionista');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _patientHeader(patient),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _reportService.printPatientReport(
                patient: patient,
                evaluations: state.evaluations,
                plans: state.plans,
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar ficha clínica PDF'),
            ),
          ),
          const SizedBox(height: 16),
          _editablePatientCard(context, patient, controller),
          const SizedBox(height: 16),
          _evaluationCard(context, patient, controller),
          const SizedBox(height: 16),
          _listCard<Evaluacion>(
            title: 'Historial de evaluaciones',
            items: state.evaluations,
            builder: (item) => ListTile(
              title: Text(item.fecha),
              subtitle: Text(
                  'Peso: ${item.peso} kg · IMC: ${item.imc.toStringAsFixed(1)}\n'
                  'Cintura: ${item.cintura} cm · Cadera: ${item.cadera} cm · '
                  'Músculo: ${item.porcentajeMusculo}%'),
              trailing: IconButton(
                tooltip: 'Editar evaluación',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    _showEvaluationEditor(context, patient, controller, item),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _comparisonCard(state.evaluations),
          const SizedBox(height: 16),
          _consultationCard(context, patient, controller, state.consultations),
          const SizedBox(height: 16),
          _planCard(context, patient, controller, state.templates),
          const SizedBox(height: 16),
          _listCard<PlanAlimenticio>(
            title: 'Planes alimenticios',
            items: state.plans,
            builder: (item) => ListTile(
              title: Text(item.titulo),
              subtitle: Text(
                  '${item.descripcion}\n${item.fechaInicio} - ${item.fechaFin}\n'
                  '${item.comidas.isEmpty ? 'Sin distribución de comidas' : item.comidas}\n'
                  'Calorías: ${item.calorias} · P: ${item.proteinas} g · '
                  'C: ${item.carbohidratos} g · G: ${item.grasasMacros} g'),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Editar plan',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    _showPlanEditor(context, patient, controller, item),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _appointmentCard(context, patient, controller),
          const SizedBox(height: 16),
          _listCard<CitaPaciente>(
            title: 'Citas',
            items: state.appointments,
            builder: (item) => ListTile(
              title: Text(item.fecha),
              subtitle: Text(
                  '${item.motivo} · ${item.estado.name} · Asistencia: ${item.asistencia}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    _showAppointmentEditor(context, patient, controller, item);
                  } else if (value == 'cancelar') {
                    controller.updateAppointment(
                      patient.id,
                      CitaPaciente(
                        id: item.id,
                        pacienteId: item.pacienteId,
                        fecha: item.fecha,
                        motivo: item.motivo,
                        estado: CitaEstado.cancelada,
                        canalRecordatorio: item.canalRecordatorio,
                      ),
                    );
                  } else if (value == 'asistio' || value == 'no_asistio') {
                    controller.updateAppointment(
                      patient.id,
                      CitaPaciente(
                        id: item.id,
                        pacienteId: item.pacienteId,
                        fecha: item.fecha,
                        motivo: item.motivo,
                        estado: item.estado,
                        canalRecordatorio: item.canalRecordatorio,
                        asistencia:
                            value == 'asistio' ? 'ASISTIÓ' : 'NO ASISTIÓ',
                        notas: item.notas,
                      ),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: 'editar', child: Text('Editar / reprogramar')),
                  PopupMenuItem(
                      value: 'cancelar', child: Text('Cancelar cita')),
                  PopupMenuItem(
                      value: 'asistio', child: Text('Marcar como asistió')),
                  PopupMenuItem(
                      value: 'no_asistio',
                      child: Text('Marcar como no asistió')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _messageCard(context, patient, controller),
          const SizedBox(height: 16),
          _listCard<MensajePaciente>(
            title: 'Chat interno',
            items: state.messages,
            builder: (item) => ListTile(
              title: Text(item.remitente),
              subtitle: Text(item.contenido),
            ),
          ),
          const SizedBox(height: 16),
          _paymentCard(context, patient, controller),
          const SizedBox(height: 16),
          _listCard<PagoPaciente>(
            title: 'Pagos',
            items: state.payments,
            builder: (item) => ListTile(
              title: Text('\$${item.monto.toStringAsFixed(2)}'),
              subtitle: Text('${item.concepto} · ${item.estado.name}'),
              trailing: IconButton(
                tooltip: 'Editar pago',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    _showPaymentEditor(context, patient, controller, item),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _documentCard(context, patient, controller),
          const SizedBox(height: 16),
          _listCard<DocumentoPaciente>(
            title: 'Documentos',
            items: state.documents,
            builder: (item) => ListTile(
              title: Text(item.nombre),
              subtitle: Text('${item.tipo} · ${item.fecha}'),
              trailing: IconButton(
                tooltip: 'Abrir documento',
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openDocument(item.uri),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _settingsCard(context, controller),
        ],
      ),
    );
  }

  Widget _patientHeader(Paciente patient) {
    final imc = _imc(patient.peso, patient.altura);
    final tmb =
        _tmb(patient.peso, patient.altura * 100, patient.edad, patient.sexo);
    final get = tmb * patient.factorActividad;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            Text(patient.correo),
            Text('Peso: ${patient.peso.toStringAsFixed(1)} kg'),
            Text('Altura: ${patient.altura.toStringAsFixed(2)} m'),
            Text(
                'Grasa corporal: ${patient.grasaCorporal.toStringAsFixed(1)} %'),
            Text('IMC: ${imc.toStringAsFixed(1)}'),
            Text('TMB: ${tmb.toStringAsFixed(0)}'),
            Text('GET: ${get.toStringAsFixed(0)}'),
            Text(
                'Alergias: ${patient.alergias.isEmpty ? 'No registradas' : patient.alergias}'),
            Text(
                'Enfermedades: ${patient.enfermedades.isEmpty ? 'No registradas' : patient.enfermedades}'),
            Text('Cintura: ${patient.cintura.toStringAsFixed(1)} cm'),
            Text('Cadera: ${patient.cadera.toStringAsFixed(1)} cm'),
            Text('Brazo: ${patient.brazo.toStringAsFixed(1)} cm'),
            Text('Músculo: ${patient.porcentajeMusculo.toStringAsFixed(1)} %'),
            if (patient.motivoConsulta.isNotEmpty)
              Text('Motivo: ${patient.motivoConsulta}'),
            if (patient.objetivos.isNotEmpty)
              Text('Objetivos: ${patient.objetivos}'),
            if (patient.medicamentos.isNotEmpty)
              Text('Medicamentos: ${patient.medicamentos}'),
          ],
        ),
      ),
    );
  }

  Widget _editablePatientCard(BuildContext context, Paciente patient,
      NutricionistaController controller) {
    final name = TextEditingController(text: patient.nombre);
    final email = TextEditingController(text: patient.correo);
    final weight = TextEditingController(text: patient.peso.toStringAsFixed(1));
    final height =
        TextEditingController(text: patient.altura.toStringAsFixed(2));
    final fat =
        TextEditingController(text: patient.grasaCorporal.toStringAsFixed(1));
    final allergies = TextEditingController(text: patient.alergias);
    final conditions = TextEditingController(text: patient.enfermedades);
    final age = TextEditingController(text: patient.edad.toString());
    final sex = TextEditingController(text: patient.sexo);
    final activity =
        TextEditingController(text: patient.factorActividad.toStringAsFixed(2));
    final phone = TextEditingController(text: patient.telefono);
    final notes = TextEditingController(text: patient.notas);
    final reason = TextEditingController(text: patient.motivoConsulta);
    final familyHistory =
        TextEditingController(text: patient.antecedentesFamiliares);
    final medicalHistory = TextEditingController(text: patient.historialMedico);
    final medications = TextEditingController(text: patient.medicamentos);
    final eatingHabits =
        TextEditingController(text: patient.habitosAlimenticios);
    final water = TextEditingController(text: patient.consumoAgua);
    final activityHabits = TextEditingController(text: patient.actividadFisica);
    final objectives = TextEditingController(text: patient.objetivos);
    final privateNotes = TextEditingController(text: patient.notasPrivadas);
    var authorization = patient.autorizacionEstado;
    var signatureData = patient.autorizacionFirma;
    final waist =
        TextEditingController(text: patient.cintura.toStringAsFixed(1));
    final hip = TextEditingController(text: patient.cadera.toStringAsFixed(1));
    final arm = TextEditingController(text: patient.brazo.toStringAsFixed(1));
    final skinfolds = TextEditingController(text: patient.plieguesCutaneos);
    final muscle = TextEditingController(
        text: patient.porcentajeMusculo.toStringAsFixed(1));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar paciente',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _fieldsGrid([
              _field(name, 'Nombre'),
              _field(email, 'Correo'),
              _field(weight, 'Peso'),
              _field(height, 'Altura'),
              _field(fat, 'Grasa corporal'),
              _field(allergies, 'Alergias'),
              _field(conditions, 'Enfermedades'),
              _field(age, 'Edad'),
              _field(sex, 'Sexo'),
              _field(activity, 'Factor actividad'),
              _field(phone, 'WhatsApp'),
              _field(reason, 'Motivo de consulta', maxLines: 2),
              _field(familyHistory, 'Antecedentes familiares', maxLines: 2),
              _field(medicalHistory, 'Historial médico', maxLines: 2),
              _field(medications, 'Medicamentos', maxLines: 2),
              _field(eatingHabits, 'Hábitos alimenticios', maxLines: 2),
              _field(water, 'Consumo de agua'),
              _field(activityHabits, 'Actividad física'),
              _field(objectives, 'Objetivos', maxLines: 2),
              _field(waist, 'Cintura (cm)'),
              _field(hip, 'Cadera (cm)'),
              _field(arm, 'Brazo (cm)'),
              _field(skinfolds, 'Pliegues cutáneos', maxLines: 2),
              _field(muscle, '% músculo'),
              _field(notes, 'Notas públicas', maxLines: 3),
              _field(privateNotes, 'Notas privadas', maxLines: 3),
              DropdownButtonFormField<String>(
                initialValue: authorization,
                decoration: const InputDecoration(
                    labelText: 'Autorización del paciente'),
                items: const [
                  DropdownMenuItem(
                      value: 'PENDIENTE', child: Text('Pendiente')),
                  DropdownMenuItem(
                      value: 'AUTORIZADA', child: Text('Autorizada')),
                  DropdownMenuItem(
                      value: 'RECHAZADA', child: Text('Rechazada')),
                ],
                onChanged: (value) => authorization = value ?? authorization,
              ),
            ]),
            OutlinedButton.icon(
              onPressed: () async {
                final value = await _captureSignature(context);
                if (value != null) setState(() => signatureData = value);
              },
              icon: const Icon(Icons.draw_outlined),
              label: Text(signatureData.isEmpty
                  ? 'Capturar firma del paciente'
                  : 'Firma capturada'),
            ),
            FilledButton(
              onPressed: () {
                controller.updatePatient(
                  patient.copyWith(
                    nombre: name.text.trim(),
                    correo: email.text.trim(),
                    peso: double.tryParse(weight.text.trim()) ?? patient.peso,
                    altura:
                        double.tryParse(height.text.trim()) ?? patient.altura,
                    grasaCorporal: double.tryParse(fat.text.trim()) ??
                        patient.grasaCorporal,
                    alergias: allergies.text.trim(),
                    enfermedades: conditions.text.trim(),
                    edad: int.tryParse(age.text.trim()) ?? patient.edad,
                    sexo: sex.text.trim(),
                    factorActividad: double.tryParse(activity.text.trim()) ??
                        patient.factorActividad,
                    telefono: phone.text.trim(),
                    notas: notes.text.trim(),
                    motivoConsulta: reason.text.trim(),
                    antecedentesFamiliares: familyHistory.text.trim(),
                    historialMedico: medicalHistory.text.trim(),
                    medicamentos: medications.text.trim(),
                    habitosAlimenticios: eatingHabits.text.trim(),
                    consumoAgua: water.text.trim(),
                    actividadFisica: activityHabits.text.trim(),
                    objetivos: objectives.text.trim(),
                    notasPrivadas: privateNotes.text.trim(),
                    cintura: double.tryParse(waist.text.replaceAll(',', '.')) ??
                        patient.cintura,
                    cadera: double.tryParse(hip.text.replaceAll(',', '.')) ??
                        patient.cadera,
                    brazo: double.tryParse(arm.text.replaceAll(',', '.')) ??
                        patient.brazo,
                    plieguesCutaneos: skinfolds.text.trim(),
                    porcentajeMusculo:
                        double.tryParse(muscle.text.replaceAll(',', '.')) ??
                            patient.porcentajeMusculo,
                    autorizacionEstado: authorization,
                    autorizacionFecha: authorization == 'AUTORIZADA'
                        ? _now()
                        : patient.autorizacionFecha,
                    autorizacionFirma: signatureData,
                  ),
                );
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _evaluationCard(BuildContext context, Paciente patient,
      NutricionistaController controller) {
    final weight = TextEditingController();
    final height = TextEditingController();
    final fat = TextEditingController();
    final waist = TextEditingController();
    final hip = TextEditingController();
    final arm = TextEditingController();
    final skinfolds = TextEditingController();
    final muscle = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar evaluación',
                style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(weight, 'Peso'),
              _field(height, 'Altura'),
              _field(fat, 'Grasa corporal'),
              _field(waist, 'Cintura (cm)'),
              _field(hip, 'Cadera (cm)'),
              _field(arm, 'Brazo (cm)'),
              _field(skinfolds, 'Pliegues cutáneos'),
              _field(muscle, '% músculo'),
            ]),
            FilledButton(
              onPressed: () {
                controller.addEvaluation(
                  patient.id,
                  double.tryParse(weight.text.trim()) ?? 0,
                  double.tryParse(height.text.trim()) ?? 0,
                  double.tryParse(fat.text.trim()) ?? 0,
                  _now(),
                  cintura:
                      double.tryParse(waist.text.replaceAll(',', '.')) ?? 0,
                  cadera: double.tryParse(hip.text.replaceAll(',', '.')) ?? 0,
                  brazo: double.tryParse(arm.text.replaceAll(',', '.')) ?? 0,
                  plieguesCutaneos: skinfolds.text.trim(),
                  porcentajeMusculo:
                      double.tryParse(muscle.text.replaceAll(',', '.')) ?? 0,
                );
              },
              child: const Text('Guardar evaluación'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _captureSignature(BuildContext context) async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Theme.of(context).colorScheme.onSurface,
      exportBackgroundColor: Colors.white,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Firma del paciente'),
        content: SizedBox(
          width: 420,
          height: 220,
          child: Signature(
            controller: controller,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: controller.clear,
            child: const Text('Borrar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final bytes = await controller.toPngBytes();
              if (bytes != null && dialogContext.mounted) {
                Navigator.pop(dialogContext, base64Encode(bytes));
              }
            },
            child: const Text('Guardar firma'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Widget _comparisonCard(List<Evaluacion> evaluations) {
    if (evaluations.length < 2) return const SizedBox.shrink();
    final previous = evaluations[evaluations.length - 2];
    final current = evaluations.last;
    String change(double value) =>
        '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comparación con la evaluación anterior',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Peso: ${change(current.peso - previous.peso)} kg'),
            Text('IMC: ${change(current.imc - previous.imc)}'),
            Text('Grasa corporal: ${change(current.grasa - previous.grasa)} %'),
            Text('Cintura: ${change(current.cintura - previous.cintura)} cm'),
            Text('Cadera: ${change(current.cadera - previous.cadera)} cm'),
            Text(
                'Músculo: ${change(current.porcentajeMusculo - previous.porcentajeMusculo)} %'),
          ],
        ),
      ),
    );
  }

  Widget _consultationCard(BuildContext context, Paciente patient,
      NutricionistaController controller, List<Consulta> consultations) {
    final reason = TextEditingController();
    final notes = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Historial clínico por consultas',
              style: Theme.of(context).textTheme.titleLarge),
          if (consultations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Todavía no hay consultas registradas.'),
            ),
          ...consultations.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.medical_information_outlined),
                title: Text(item.fecha),
                subtitle: Text('${item.motivo}\n${item.notas}'),
                isThreeLine: true,
              )),
          _field(reason, 'Motivo de consulta'),
          _field(notes, 'Notas de la consulta', maxLines: 3),
          FilledButton.icon(
            onPressed: () {
              controller.addConsultation(
                patient.id,
                Consulta(
                  id: 0,
                  pacienteId: patient.id,
                  fecha: _now(),
                  motivo: reason.text.trim(),
                  notas: notes.text.trim(),
                  estado: 'REALIZADA',
                ),
              );
              reason.clear();
              notes.clear();
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar consulta'),
          ),
        ]),
      ),
    );
  }

  Widget _planCard(BuildContext context, Paciente patient,
      NutricionistaController controller, List<PlantillaPlan> templates) {
    final title = TextEditingController(text: 'Plan general');
    final objective = TextEditingController();
    final condition = TextEditingController();
    final description = TextEditingController();
    final start = TextEditingController(text: _today());
    final end = TextEditingController();
    final meals = TextEditingController();
    final substitutions = TextEditingController();
    final calories = TextEditingController();
    final protein = TextEditingController();
    final carbs = TextEditingController();
    final fats = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Planes alimenticios',
                style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(title, 'Título'),
              _field(objective, 'Objetivo'),
              _field(condition, 'Condición'),
              _field(start, 'Fecha inicio'),
              _field(end, 'Fecha fin'),
              _field(description, 'Descripción', maxLines: 3),
              _field(meals, 'Comidas y porciones', maxLines: 3),
              _field(substitutions, 'Sustituciones', maxLines: 2),
              _field(calories, 'Calorías'),
              _field(protein, 'Proteínas (g)'),
              _field(carbs, 'Carbohidratos (g)'),
              _field(fats, 'Grasas (g)'),
            ]),
            Wrap(
              spacing: 8,
              children: templates
                  .map(
                    (template) => ActionChip(
                      label: Text(template.nombre),
                      onPressed: () {
                        title.text = template.nombre;
                        objective.text = template.objetivo;
                        condition.text = template.condicion;
                        description.text = template.descripcion;
                      },
                    ),
                  )
                  .toList(),
            ),
            FilledButton(
              onPressed: () {
                controller.addPlan(
                  patient.id,
                  PlanAlimenticio(
                    id: 0,
                    pacienteId: patient.id,
                    titulo: title.text.trim().isEmpty
                        ? 'Plan general'
                        : title.text.trim(),
                    descripcion: description.text.trim(),
                    objetivo: objective.text.trim(),
                    condicion: condition.text.trim(),
                    plantillaNombre:
                        templates.isNotEmpty ? templates.first.nombre : '',
                    fechaInicio: start.text.trim(),
                    fechaFin: end.text.trim(),
                    comidas: meals.text.trim(),
                    sustituciones: substitutions.text.trim(),
                    calorias:
                        double.tryParse(calories.text.replaceAll(',', '.')) ??
                            0,
                    proteinas:
                        double.tryParse(protein.text.replaceAll(',', '.')) ?? 0,
                    carbohidratos:
                        double.tryParse(carbs.text.replaceAll(',', '.')) ?? 0,
                    grasasMacros:
                        double.tryParse(fats.text.replaceAll(',', '.')) ?? 0,
                  ),
                );
              },
              child: const Text('Guardar plan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEvaluationEditor(
    BuildContext context,
    Paciente patient,
    NutricionistaController controller,
    Evaluacion evaluation,
  ) async {
    final weight =
        TextEditingController(text: evaluation.peso.toStringAsFixed(1));
    final height =
        TextEditingController(text: evaluation.altura.toStringAsFixed(2));
    final fat =
        TextEditingController(text: evaluation.grasa.toStringAsFixed(1));
    final waist =
        TextEditingController(text: evaluation.cintura.toStringAsFixed(1));
    final hip =
        TextEditingController(text: evaluation.cadera.toStringAsFixed(1));
    final arm =
        TextEditingController(text: evaluation.brazo.toStringAsFixed(1));
    final skinfolds = TextEditingController(text: evaluation.plieguesCutaneos);
    final muscle = TextEditingController(
        text: evaluation.porcentajeMusculo.toStringAsFixed(1));
    final date = TextEditingController(text: evaluation.fecha);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar evaluación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(weight, 'Peso', keyboardType: TextInputType.number),
              _dialogField(height, 'Altura',
                  keyboardType: TextInputType.number),
              _dialogField(fat, 'Grasa corporal',
                  keyboardType: TextInputType.number),
              _dialogField(waist, 'Cintura (cm)',
                  keyboardType: TextInputType.number),
              _dialogField(hip, 'Cadera (cm)',
                  keyboardType: TextInputType.number),
              _dialogField(arm, 'Brazo (cm)',
                  keyboardType: TextInputType.number),
              _dialogField(skinfolds, 'Pliegues cutáneos'),
              _dialogField(muscle, '% músculo',
                  keyboardType: TextInputType.number),
              _dialogField(date, 'Fecha'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final peso = double.tryParse(weight.text.replaceAll(',', '.'));
              final altura = double.tryParse(height.text.replaceAll(',', '.'));
              final grasa = double.tryParse(fat.text.replaceAll(',', '.'));
              if (peso == null ||
                  altura == null ||
                  grasa == null ||
                  peso <= 0 ||
                  altura <= 0 ||
                  grasa < 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                      content: Text('Ingresa valores nutricionales válidos')),
                );
                return;
              }
              controller.updateEvaluation(
                patient.id,
                Evaluacion(
                  id: evaluation.id,
                  pacienteId: evaluation.pacienteId,
                  peso: peso,
                  altura: altura,
                  imc: evaluation.imc,
                  tmb: evaluation.tmb,
                  get: evaluation.get,
                  grasa: grasa,
                  fecha: date.text.trim().isEmpty
                      ? evaluation.fecha
                      : date.text.trim(),
                  cintura: double.tryParse(waist.text.replaceAll(',', '.')) ??
                      evaluation.cintura,
                  cadera: double.tryParse(hip.text.replaceAll(',', '.')) ??
                      evaluation.cadera,
                  brazo: double.tryParse(arm.text.replaceAll(',', '.')) ??
                      evaluation.brazo,
                  plieguesCutaneos: skinfolds.text.trim(),
                  porcentajeMusculo:
                      double.tryParse(muscle.text.replaceAll(',', '.')) ??
                          evaluation.porcentajeMusculo,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
    weight.dispose();
    height.dispose();
    fat.dispose();
    date.dispose();
  }

  Widget _appointmentCard(BuildContext context, Paciente patient,
      NutricionistaController controller) {
    final date = TextEditingController();
    final reason = TextEditingController();
    final state = TextEditingController(text: 'AGENDADA');
    final channel = TextEditingController(text: 'WhatsApp y email');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agenda y citas',
                style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              TextField(
                controller: date,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha y hora'),
                onTap: () async {
                  final value = await _pickDateTime(context, date.text);
                  if (value != null) date.text = value;
                },
              ),
              _field(reason, 'Motivo'),
              _field(state, 'Estado'),
              _field(channel, 'Canal recordatorio'),
            ]),
            FilledButton(
              onPressed: () {
                controller.addAppointment(
                  patient.id,
                  CitaPaciente(
                    id: 0,
                    pacienteId: patient.id,
                    fecha: date.text.trim(),
                    motivo: reason.text.trim(),
                    estado: _stateFromText(state.text),
                    canalRecordatorio: channel.text.trim(),
                  ),
                );
              },
              child: const Text('Guardar cita'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageCard(BuildContext context, Paciente patient,
      NutricionistaController controller) {
    final message = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comunicación', style: Theme.of(context).textTheme.titleLarge),
            _field(message, 'Mensaje', maxLines: 4),
            FilledButton(
              onPressed: () {
                controller.addMessage(
                  patient.id,
                  MensajePaciente(
                    id: 0,
                    pacienteId: patient.id,
                    remitente: 'nutricionista',
                    contenido: message.text.trim(),
                    fecha: _now(),
                  ),
                );
              },
              child: const Text('Enviar mensaje'),
            ),
            FilledButton.tonal(
              onPressed: patient.telefono.isEmpty
                  ? null
                  : () => _openWhatsapp(patient.telefono,
                      'Hola ${patient.nombre}, te escribo desde NNEN.'),
              child: const Text('Abrir WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(BuildContext context, Paciente patient,
      NutricionistaController controller) {
    final amount = TextEditingController();
    final concept = TextEditingController(text: 'Consulta nutricional');
    final state = TextEditingController(text: 'PENDIENTE');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pagos y facturación',
                style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(amount, 'Monto'),
              _field(concept, 'Concepto'),
              _field(state, 'Estado'),
            ]),
            FilledButton(
              onPressed: () {
                controller.addPayment(
                  patient.id,
                  PagoPaciente(
                    id: 0,
                    pacienteId: patient.id,
                    monto: double.tryParse(amount.text.trim()) ?? 0,
                    concepto: concept.text.trim(),
                    fecha: _now(),
                    estado: state.text.trim().toUpperCase() == 'PAGADO'
                        ? PagoEstado.pagado
                        : PagoEstado.pendiente,
                  ),
                );
              },
              child: const Text('Registrar pago'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(BuildContext context, Paciente patient,
      NutricionistaController controller) {
    final name = TextEditingController();
    final type = TextEditingController(text: 'Laboratorio');
    final uri = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos adjuntos',
                style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(name, 'Nombre'),
              _field(type, 'Tipo'),
              _field(uri, 'URI o ruta'),
            ]),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );
                final file = result.isEmpty ? null : result.single;
                if (file == null) return;
                name.text = file.name;
                uri.text = file.path ?? file.name;
                type.text = file.extension?.toUpperCase() ?? 'Documento';
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('Seleccionar laboratorio, foto o PDF'),
            ),
            FilledButton(
              onPressed: () {
                final path = uri.text.trim();
                if (path.isEmpty) return;
                if (path.startsWith('http') || path == name.text.trim()) {
                  controller.addDocument(
                    patient.id,
                    DocumentoPaciente(
                      id: 0,
                      pacienteId: patient.id,
                      nombre: name.text.trim(),
                      tipo: type.text.trim(),
                      uri: path,
                      fecha: _now(),
                    ),
                  );
                } else {
                  controller.uploadDocument(patient.id, path,
                      nombre: name.text.trim());
                }
              },
              child: const Text('Guardar documento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(
      BuildContext context, NutricionistaController controller) {
    final price = TextEditingController(
        text: controller.state.settings?.precioConsulta.toStringAsFixed(2) ??
            '0');
    final whatsapp =
        TextEditingController(text: controller.state.settings?.whatsapp ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuración básica',
                style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(price, 'Precio de consulta'),
              _field(whatsapp, 'WhatsApp profesional'),
            ]),
            FilledButton(
              onPressed: () {
                controller.saveSettings(
                  NutricionistaSettings(
                    precioConsulta: double.tryParse(price.text.trim()) ?? 0,
                    whatsapp: whatsapp.text.trim(),
                  ),
                );
              },
              child: const Text('Guardar configuración'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPlanEditor(
    BuildContext context,
    Paciente patient,
    NutricionistaController controller,
    PlanAlimenticio plan,
  ) async {
    final title = TextEditingController(text: plan.titulo);
    final objective = TextEditingController(text: plan.objetivo);
    final condition = TextEditingController(text: plan.condicion);
    final description = TextEditingController(text: plan.descripcion);
    final start = TextEditingController(text: plan.fechaInicio);
    final end = TextEditingController(text: plan.fechaFin);
    final meals = TextEditingController(text: plan.comidas);
    final substitutions = TextEditingController(text: plan.sustituciones);
    final calories = TextEditingController(text: plan.calorias.toString());
    final protein = TextEditingController(text: plan.proteinas.toString());
    final carbs = TextEditingController(text: plan.carbohidratos.toString());
    final fats = TextEditingController(text: plan.grasasMacros.toString());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar plan alimenticio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(title, 'Título'),
              _dialogField(objective, 'Objetivo'),
              _dialogField(condition, 'Condición'),
              _dialogField(start, 'Fecha de inicio'),
              _dialogField(end, 'Fecha de fin'),
              _dialogField(description, 'Descripción', maxLines: 4),
              _dialogField(meals, 'Comidas y porciones', maxLines: 4),
              _dialogField(substitutions, 'Sustituciones', maxLines: 3),
              _dialogField(calories, 'Calorías',
                  keyboardType: TextInputType.number),
              _dialogField(protein, 'Proteínas (g)',
                  keyboardType: TextInputType.number),
              _dialogField(carbs, 'Carbohidratos (g)',
                  keyboardType: TextInputType.number),
              _dialogField(fats, 'Grasas (g)',
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              controller.updatePlan(
                patient.id,
                PlanAlimenticio(
                  id: plan.id,
                  pacienteId: patient.id,
                  titulo: title.text.trim(),
                  descripcion: description.text.trim(),
                  objetivo: objective.text.trim(),
                  condicion: condition.text.trim(),
                  plantillaNombre: plan.plantillaNombre,
                  fechaInicio: start.text.trim(),
                  fechaFin: end.text.trim(),
                  comidas: meals.text.trim(),
                  sustituciones: substitutions.text.trim(),
                  calorias:
                      double.tryParse(calories.text.replaceAll(',', '.')) ??
                          plan.calorias,
                  proteinas:
                      double.tryParse(protein.text.replaceAll(',', '.')) ??
                          plan.proteinas,
                  carbohidratos:
                      double.tryParse(carbs.text.replaceAll(',', '.')) ??
                          plan.carbohidratos,
                  grasasMacros:
                      double.tryParse(fats.text.replaceAll(',', '.')) ??
                          plan.grasasMacros,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAppointmentEditor(
    BuildContext context,
    Paciente patient,
    NutricionistaController controller,
    CitaPaciente appointment,
  ) async {
    final date = TextEditingController(text: appointment.fecha);
    final reason = TextEditingController(text: appointment.motivo);
    final channel = TextEditingController(text: appointment.canalRecordatorio);
    var status = appointment.estado;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar cita'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: date,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Fecha y hora'),
                  onTap: () async {
                    final value = await _pickDateTime(context, date.text);
                    if (value != null) date.text = value;
                  },
                ),
                _dialogField(reason, 'Motivo'),
                DropdownButtonFormField<CitaEstado>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(
                        value: CitaEstado.agendada, child: Text('Agendada')),
                    DropdownMenuItem(
                        value: CitaEstado.reprogramada,
                        child: Text('Reprogramada')),
                    DropdownMenuItem(
                        value: CitaEstado.completada,
                        child: Text('Completada')),
                    DropdownMenuItem(
                        value: CitaEstado.cancelada, child: Text('Cancelada')),
                  ],
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                ),
                _dialogField(channel, 'Canal de recordatorio'),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                controller.updateAppointment(
                  patient.id,
                  CitaPaciente(
                    id: appointment.id,
                    pacienteId: patient.id,
                    fecha: date.text.trim(),
                    motivo: reason.text.trim(),
                    estado: status,
                    canalRecordatorio: channel.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentEditor(
    BuildContext context,
    Paciente patient,
    NutricionistaController controller,
    PagoPaciente payment,
  ) async {
    final amount =
        TextEditingController(text: payment.monto.toStringAsFixed(2));
    final concept = TextEditingController(text: payment.concepto);
    final date = TextEditingController(text: payment.fecha);
    var status = payment.estado;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(amount, 'Monto', keyboardType: TextInputType.number),
              _dialogField(concept, 'Concepto'),
              _dialogField(date, 'Fecha'),
              DropdownButtonFormField<PagoEstado>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(
                      value: PagoEstado.pendiente, child: Text('Pendiente')),
                  DropdownMenuItem(
                      value: PagoEstado.pagado, child: Text('Pagado')),
                ],
                onChanged: (value) => setState(() => status = value ?? status),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                controller.updatePayment(
                  patient.id,
                  PagoPaciente(
                    id: payment.id,
                    pacienteId: patient.id,
                    monto: double.tryParse(amount.text.replaceAll(',', '.')) ??
                        payment.monto,
                    concepto: concept.text.trim(),
                    fecha: date.text.trim(),
                    estado: status,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<String?> _pickDateTime(BuildContext context, String current) async {
    final parsed =
        DateTime.tryParse(current.replaceFirst(' ', 'T')) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(parsed));
    if (time == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _listCard<T>({
    required String title,
    required List<T> items,
    required Widget Function(T item) builder,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Sin registros')
            else
              ...items.map(builder),
          ],
        ),
      ),
    );
  }

  Widget _fieldsGrid(List<Widget> widgets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 800;
        if (!wide) {
          return Column(children: widgets);
        }
        return Wrap(
          spacing: 16,
          runSpacing: 8,
          children: widgets
              .map(
                (w) =>
                    SizedBox(width: (constraints.maxWidth / 2) - 16, child: w),
              )
              .toList(),
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  CitaEstado _stateFromText(String value) {
    return switch (value.toUpperCase()) {
      'REPROGRAMADA' => CitaEstado.reprogramada,
      'COMPLETADA' => CitaEstado.completada,
      'CANCELADA' => CitaEstado.cancelada,
      _ => CitaEstado.agendada,
    };
  }

  Future<void> _openDocument(String value) async {
    final normalized = value.startsWith('/uploads/')
        ? '${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api$'), '')}$value'
        : value;
    final uri = normalized.startsWith('http')
        ? Uri.tryParse(normalized)
        : Uri.file(normalized);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  double _imc(double peso, double altura) =>
      altura <= 0 ? 0 : peso / (altura * altura);
  double _tmb(double peso, double alturaCm, int edad, String sexo) {
    final adjust = sexo.toLowerCase().contains('masc') ? 5 : -161;
    return (10 * peso) + (6.25 * alturaCm) - (5 * edad) + adjust;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _now() {
    final now = DateTime.now();
    return '${_today()} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openWhatsapp(String number, String message) async {
    final uri = Uri.parse(
        'https://wa.me/${number.replaceAll(RegExp(r'\\D'), '')}?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
