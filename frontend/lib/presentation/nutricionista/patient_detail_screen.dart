import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/entities/cita_paciente.dart';
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
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
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
              subtitle: Text('Peso: ${item.peso} kg · IMC: ${item.imc.toStringAsFixed(1)}'),
            ),
          ),
          const SizedBox(height: 16),
          _planCard(context, patient, controller, state.templates),
          const SizedBox(height: 16),
          _listCard<PlanAlimenticio>(
            title: 'Planes alimenticios',
            items: state.plans,
            builder: (item) => ListTile(
              title: Text(item.titulo),
              subtitle: Text(item.descripcion),
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
              subtitle: Text('${item.motivo} · ${item.estado.name}'),
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
    final tmb = _tmb(patient.peso, patient.altura * 100, patient.edad, patient.sexo);
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
            Text('Grasa corporal: ${patient.grasaCorporal.toStringAsFixed(1)} %'),
            Text('IMC: ${imc.toStringAsFixed(1)}'),
            Text('TMB: ${tmb.toStringAsFixed(0)}'),
            Text('GET: ${get.toStringAsFixed(0)}'),
            Text('Alergias: ${patient.alergias.isEmpty ? 'No registradas' : patient.alergias}'),
            Text('Enfermedades: ${patient.enfermedades.isEmpty ? 'No registradas' : patient.enfermedades}'),
          ],
        ),
      ),
    );
  }

  Widget _editablePatientCard(BuildContext context, Paciente patient, NutricionistaController controller) {
    final name = TextEditingController(text: patient.nombre);
    final email = TextEditingController(text: patient.correo);
    final weight = TextEditingController(text: patient.peso.toStringAsFixed(1));
    final height = TextEditingController(text: patient.altura.toStringAsFixed(2));
    final fat = TextEditingController(text: patient.grasaCorporal.toStringAsFixed(1));
    final allergies = TextEditingController(text: patient.alergias);
    final conditions = TextEditingController(text: patient.enfermedades);
    final age = TextEditingController(text: patient.edad.toString());
    final sex = TextEditingController(text: patient.sexo);
    final activity = TextEditingController(text: patient.factorActividad.toStringAsFixed(2));
    final phone = TextEditingController(text: patient.telefono);
    final notes = TextEditingController(text: patient.notas);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar paciente', style: Theme.of(context).textTheme.titleLarge),
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
              _field(notes, 'Notas', maxLines: 3),
            ]),
            FilledButton(
              onPressed: () {
                controller.updatePatient(
                  patient.copyWith(
                    nombre: name.text.trim(),
                    correo: email.text.trim(),
                    peso: double.tryParse(weight.text.trim()) ?? patient.peso,
                    altura: double.tryParse(height.text.trim()) ?? patient.altura,
                    grasaCorporal: double.tryParse(fat.text.trim()) ?? patient.grasaCorporal,
                    alergias: allergies.text.trim(),
                    enfermedades: conditions.text.trim(),
                    edad: int.tryParse(age.text.trim()) ?? patient.edad,
                    sexo: sex.text.trim(),
                    factorActividad: double.tryParse(activity.text.trim()) ?? patient.factorActividad,
                    telefono: phone.text.trim(),
                    notas: notes.text.trim(),
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

  Widget _evaluationCard(BuildContext context, Paciente patient, NutricionistaController controller) {
    final weight = TextEditingController();
    final height = TextEditingController();
    final fat = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar evaluación', style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(weight, 'Peso'),
              _field(height, 'Altura'),
              _field(fat, 'Grasa corporal'),
            ]),
            FilledButton(
              onPressed: () {
                controller.addEvaluation(
                  patient.id,
                  double.tryParse(weight.text.trim()) ?? 0,
                  double.tryParse(height.text.trim()) ?? 0,
                  double.tryParse(fat.text.trim()) ?? 0,
                  _now(),
                );
              },
              child: const Text('Guardar evaluación'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(BuildContext context, Paciente patient, NutricionistaController controller, List<PlantillaPlan> templates) {
    final title = TextEditingController(text: 'Plan general');
    final objective = TextEditingController();
    final condition = TextEditingController();
    final description = TextEditingController();
    final start = TextEditingController(text: _today());
    final end = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Planes alimenticios', style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(title, 'Título'),
              _field(objective, 'Objetivo'),
              _field(condition, 'Condición'),
              _field(start, 'Fecha inicio'),
              _field(end, 'Fecha fin'),
              _field(description, 'Descripción', maxLines: 3),
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
                    titulo: title.text.trim().isEmpty ? 'Plan general' : title.text.trim(),
                    descripcion: description.text.trim(),
                    objetivo: objective.text.trim(),
                    condicion: condition.text.trim(),
                    plantillaNombre: templates.isNotEmpty ? templates.first.nombre : '',
                    fechaInicio: start.text.trim(),
                    fechaFin: end.text.trim(),
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

  Widget _appointmentCard(BuildContext context, Paciente patient, NutricionistaController controller) {
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
            Text('Agenda y citas', style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(date, 'Fecha y hora'),
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

  Widget _messageCard(BuildContext context, Paciente patient, NutricionistaController controller) {
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
                  : () => _openWhatsapp(patient.telefono, 'Hola ${patient.nombre}, te escribo desde NNEN.'),
              child: const Text('Abrir WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(BuildContext context, Paciente patient, NutricionistaController controller) {
    final amount = TextEditingController();
    final concept = TextEditingController(text: 'Consulta nutricional');
    final state = TextEditingController(text: 'PENDIENTE');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pagos y facturación', style: Theme.of(context).textTheme.titleLarge),
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

  Widget _documentCard(BuildContext context, Paciente patient, NutricionistaController controller) {
    final name = TextEditingController();
    final type = TextEditingController(text: 'Laboratorio');
    final uri = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos adjuntos', style: Theme.of(context).textTheme.titleLarge),
            _fieldsGrid([
              _field(name, 'Nombre'),
              _field(type, 'Tipo'),
              _field(uri, 'URI o ruta'),
            ]),
            FilledButton(
              onPressed: () {
                controller.addDocument(
                  patient.id,
                  DocumentoPaciente(
                    id: 0,
                    pacienteId: patient.id,
                    nombre: name.text.trim(),
                    tipo: type.text.trim(),
                    uri: uri.text.trim(),
                    fecha: _now(),
                  ),
                );
              },
              child: const Text('Guardar documento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, NutricionistaController controller) {
    final price = TextEditingController(text: controller.state.settings?.precioConsulta.toStringAsFixed(2) ?? '0');
    final whatsapp = TextEditingController(text: controller.state.settings?.whatsapp ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuración básica', style: Theme.of(context).textTheme.titleLarge),
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
                (w) => SizedBox(width: (constraints.maxWidth / 2) - 16, child: w),
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

  double _imc(double peso, double altura) => altura <= 0 ? 0 : peso / (altura * altura);
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
    final uri = Uri.parse('https://wa.me/${number.replaceAll(RegExp(r'\\D'), '')}?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
