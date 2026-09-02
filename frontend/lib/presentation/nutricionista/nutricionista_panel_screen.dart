import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/plantilla_plan.dart';
import 'nutricionista_controller.dart';
import 'nutricionista_state.dart';

class NutritionistPanelScreen extends ConsumerStatefulWidget {
  const NutritionistPanelScreen({super.key});

  @override
  ConsumerState<NutritionistPanelScreen> createState() => _NutritionistPanelScreenState();
}

class _NutritionistPanelScreenState extends ConsumerState<NutritionistPanelScreen> {
  final _drawerKey = GlobalKey<ScaffoldState>();
  final _patientFormKey = GlobalKey<FormState>();
  final _planFormKey = GlobalKey<FormState>();
  final _appointmentFormKey = GlobalKey<FormState>();
  final _messageFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _templateFormKey = GlobalKey<FormState>();
  final _settingsFormKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _fat = TextEditingController();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();
  final _age = TextEditingController(text: '30');
  final _sex = TextEditingController(text: 'Femenino');
  final _activity = TextEditingController(text: '1.2');
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  final _evaluationWeight = TextEditingController();
  final _evaluationHeight = TextEditingController();
  final _evaluationFat = TextEditingController();

  final _planTitle = TextEditingController(text: 'Plan general');
  final _planObjective = TextEditingController();
  final _planCondition = TextEditingController();
  final _planDescription = TextEditingController();
  final _planStart = TextEditingController();
  final _planEnd = TextEditingController();

  final _appointmentDate = TextEditingController();
  final _appointmentReason = TextEditingController();
  final _appointmentStatus = TextEditingController(text: 'AGENDADA');
  final _appointmentChannel = TextEditingController(text: 'WhatsApp y email');

  final _messageContent = TextEditingController();
  final _paymentAmount = TextEditingController();
  final _paymentConcept = TextEditingController(text: 'Consulta nutricional');
  final _paymentStatus = TextEditingController(text: 'PENDIENTE');
  final _documentName = TextEditingController();
  final _documentType = TextEditingController(text: 'Laboratorio');
  final _documentUri = TextEditingController();
  final _templateName = TextEditingController();
  final _templateObjective = TextEditingController();
  final _templateCondition = TextEditingController();
  final _templateDescription = TextEditingController();
  final _price = TextEditingController();
  final _whatsapp = TextEditingController();
  int? _lastAppliedPatientId;

  @override
  void initState() {
    super.initState();
    _planStart.text = _today();
    _appointmentStatus.text = 'AGENDADA';
    _appointmentChannel.text = 'WhatsApp y email';
    _paymentConcept.text = 'Consulta nutricional';
    _paymentStatus.text = 'PENDIENTE';
    _documentType.text = 'Laboratorio';
    _templateName.text = '';
    _templateObjective.text = '';
    _templateCondition.text = '';
    _templateDescription.text = '';
    _price.text = '0';
    _whatsapp.text = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionistControllerProvider).loadAll();
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _weight,
      _height,
      _fat,
      _allergies,
      _conditions,
      _age,
      _sex,
      _activity,
      _phone,
      _notes,
      _evaluationWeight,
      _evaluationHeight,
      _evaluationFat,
      _planTitle,
      _planObjective,
      _planCondition,
      _planDescription,
      _planStart,
      _planEnd,
      _appointmentDate,
      _appointmentReason,
      _appointmentStatus,
      _appointmentChannel,
      _messageContent,
      _paymentAmount,
      _paymentConcept,
      _paymentStatus,
      _documentName,
      _documentType,
      _documentUri,
      _templateName,
      _templateObjective,
      _templateCondition,
      _templateDescription,
      _price,
      _whatsapp,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(nutritionistControllerProvider);
    final state = controller.state;
    final session = ref.watch(authControllerProvider).state.session;

    if (state.selectedPatient != null && state.selectedPatient!.id != _lastAppliedPatientId) {
      _applyPatientToForm(state.selectedPatient!);
      _lastAppliedPatientId = state.selectedPatient!.id;
    }
    if (state.settings != null) {
      _price.text = state.settings!.precioConsulta.toStringAsFixed(2);
      _whatsapp.text = state.settings!.whatsapp;
    }

    return Scaffold(
      key: _drawerKey,
      appBar: AppBar(
        title: Text(
          'NNEN · ${session?.name ?? 'Nutricionista'}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _drawerKey.currentState?.openDrawer(),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.loadAll(),
            child: const Text('Actualizar'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                child: Text(
                  'Menú del nutricionista',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              _drawerItem(state, NutricionistaSection.dashboard, 'Dashboard', Icons.dashboard),
              _drawerItem(state, NutricionistaSection.agregarPaciente, 'Agregar paciente', Icons.person_add),
              _drawerItem(state, NutricionistaSection.misPacientes, 'Mis pacientes', Icons.people),
              _drawerItem(state, NutricionistaSection.planes, 'Planes alimenticios', Icons.restaurant_menu),
              _drawerItem(state, NutricionistaSection.agenda, 'Agenda y citas', Icons.calendar_month),
              _drawerItem(state, NutricionistaSection.comunicacion, 'Comunicación', Icons.chat),
              _drawerItem(state, NutricionistaSection.pagos, 'Pagos y facturación', Icons.payments),
              _drawerItem(state, NutricionistaSection.configuracion, 'Configuración', Icons.settings),
            ],
          ),
        ),
      ),
      body: controller.state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.message != null) _InfoBanner(message: state.message!),
                  _buildHeader(state),
                  const SizedBox(height: 16),
                  switch (state.section) {
                    NutricionistaSection.dashboard => _dashboardSection(context, state, controller),
                    NutricionistaSection.agregarPaciente => _addPatientSection(context, controller),
                    NutricionistaSection.misPacientes => _patientsSection(context, state, controller),
                    NutricionistaSection.planes => _plansSection(context, state, controller),
                    NutricionistaSection.agenda => _appointmentsSection(context, state, controller),
                    NutricionistaSection.comunicacion => _communicationSection(context, state, controller),
                    NutricionistaSection.pagos => _paymentsSection(context, state, controller),
                    NutricionistaSection.configuracion => _settingsSection(context, state, controller),
                  },
                ],
              ),
            ),
    );
  }

  Widget _drawerItem(
    NutricionistaState state,
    NutricionistaSection section,
    String label,
    IconData icon,
  ) {
    final selected = state.section == section;
    return ListTile(
      leading: Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : null),
      title: Text(label),
      selected: selected,
      onTap: () {
        ref.read(nutritionistControllerProvider).setSection(section);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildHeader(NutricionistaState state) {
    final summary = state.summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel clínico',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Administra pacientes, historias, planes y seguimiento desde una sola vista.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (summary != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metric('Pacientes', summary.totalPacientes.toString()),
                  _metric('Evaluaciones', summary.totalEvaluaciones.toString()),
                  _metric('Planes', summary.totalPlanes.toString()),
                  _metric('Citas', summary.totalCitas.toString()),
                  _metric('Pagos pendientes', summary.pagosPendientes.toString()),
                  _metric('IMC promedio', summary.imcPromedio.toStringAsFixed(1)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _dashboardSection(
    BuildContext context,
    NutricionistaState state,
    NutricionistaController controller,
  ) {
    final patient = state.selectedPatient ?? (state.pacientes.isNotEmpty ? state.pacientes.first : null);
    final evaluations = state.evaluations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pacientes recientes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...state.pacientes.take(5).map((p) => _patientCard(p, controller)),
        const SizedBox(height: 20),
        Text('Evolución clínica', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _progressChart(evaluations),
        const SizedBox(height: 20),
        if (patient != null) _quickPatientPreview(patient),
      ],
    );
  }

  Widget _addPatientSection(BuildContext context, NutricionistaController controller) {
    return Form(
      key: _patientFormKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agregar paciente completo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _twoColumn([
                _field(_name, 'Nombre completo', validator: _required),
                _field(_email, 'Correo', keyboardType: TextInputType.emailAddress, validator: _emailValidator),
                _field(_weight, 'Peso (kg)', keyboardType: TextInputType.number, validator: _numberValidator),
                _field(_height, 'Altura (m)', keyboardType: TextInputType.number, validator: _numberValidator),
                _field(_fat, 'Grasa corporal %', keyboardType: TextInputType.number, validator: _numberValidator),
                _field(_age, 'Edad', keyboardType: TextInputType.number, validator: _numberValidator),
                _field(_sex, 'Sexo', validator: _required),
                _field(_activity, 'Factor actividad', keyboardType: TextInputType.number, validator: _numberValidator),
                _field(_phone, 'WhatsApp / Teléfono'),
                _field(_allergies, 'Alergias'),
                _field(_conditions, 'Enfermedades'),
                _field(_notes, 'Notas'),
              ]),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_patientFormKey.currentState!.validate()) return;
                  final paciente = Paciente(
                    id: 0,
                    nombre: _name.text.trim(),
                    correo: _email.text.trim(),
                    nutricionistaId: 0,
                    peso: _double(_weight),
                    altura: _double(_height),
                    grasaCorporal: _double(_fat),
                    alergias: _allergies.text.trim(),
                    enfermedades: _conditions.text.trim(),
                    edad: _int(_age),
                    sexo: _sex.text.trim(),
                    factorActividad: _double(_activity),
                    telefono: _phone.text.trim(),
                    notas: _notes.text.trim(),
                  );
                  controller.createPatient(paciente);
                  _clearPatientForm();
                },
                child: const Text('Guardar paciente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _patientsSection(BuildContext context, NutricionistaState state, NutricionistaController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis pacientes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...state.pacientes.map((p) => _patientCard(p, controller, showDetail: true)),
      ],
    );
  }

  Widget _plansSection(BuildContext context, NutricionistaState state, NutricionistaController controller) {
    final patient = state.selectedPatient;
    if (patient == null) {
      return const Text('Selecciona un paciente para crear y reutilizar planes.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Planes alimenticios', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Form(
          key: _planFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _field(_planTitle, 'Título'),
                  _field(_planObjective, 'Objetivo'),
                  _field(_planCondition, 'Condición'),
                  _field(_planDescription, 'Descripción', maxLines: 4, validator: _required),
                  _twoColumn([
                    _field(_planStart, 'Fecha inicio', validator: _required),
                    _field(_planEnd, 'Fecha fin', validator: _required),
                  ]),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      if (!_planFormKey.currentState!.validate()) return;
                      controller.addPlan(
                        patient.id,
                        PlanAlimenticio(
                          id: 0,
                          pacienteId: patient.id,
                          titulo: _planTitle.text.trim().isEmpty ? 'Plan general' : _planTitle.text.trim(),
                          descripcion: _planDescription.text.trim(),
                          objetivo: _planObjective.text.trim(),
                          condicion: _planCondition.text.trim(),
                          plantillaNombre: state.templates.isNotEmpty ? state.templates.first.nombre : '',
                          fechaInicio: _planStart.text.trim(),
                          fechaFin: _planEnd.text.trim(),
                        ),
                      );
                      _planDescription.clear();
                    },
                    child: const Text('Guardar plan'),
                  ),
                  const SizedBox(height: 12),
                  if (state.templates.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: state.templates.map((template) {
                        return ActionChip(
                          label: Text(template.nombre),
                          onPressed: () {
                            _templateName.text = template.nombre;
                            _planObjective.text = template.objetivo;
                            _planCondition.text = template.condicion;
                            _planDescription.text = template.descripcion;
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...state.plans.map((plan) => Card(
              child: ListTile(
                title: Text(plan.titulo),
                subtitle: Text('${plan.objetivo} · ${plan.condicion}\n${plan.descripcion}'),
              ),
            )),
        const SizedBox(height: 16),
        Form(
          key: _templateFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Crear plantilla', style: Theme.of(context).textTheme.titleMedium),
                  _field(_templateName, 'Nombre plantilla', validator: _required),
                  _field(_templateObjective, 'Objetivo'),
                  _field(_templateCondition, 'Condición'),
                  _field(_templateDescription, 'Descripción', maxLines: 4, validator: _required),
                  FilledButton(
                    onPressed: () {
                      if (!_templateFormKey.currentState!.validate()) return;
                      controller.saveTemplate(
                        PlantillaPlan(
                          id: 0,
                          nombre: _templateName.text.trim(),
                          objetivo: _templateObjective.text.trim(),
                          condicion: _templateCondition.text.trim(),
                          descripcion: _templateDescription.text.trim(),
                        ),
                      );
                      _templateFormKey.currentState!.reset();
                    },
                    child: const Text('Guardar plantilla'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _appointmentsSection(BuildContext context, NutricionistaState state, NutricionistaController controller) {
    final patient = state.selectedPatient;
    if (patient == null) return const Text('Selecciona un paciente para agendar citas.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agenda y citas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Form(
          key: _appointmentFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _field(_appointmentDate, 'Fecha y hora', validator: _required),
                  _field(_appointmentReason, 'Motivo', validator: _required),
                  _field(_appointmentStatus, 'Estado', validator: _required),
                  _field(_appointmentChannel, 'Canal de recordatorio', validator: _required),
                  FilledButton(
                    onPressed: () {
                      if (!_appointmentFormKey.currentState!.validate()) return;
                      controller.addAppointment(
                        patient.id,
                        CitaPaciente(
                          id: 0,
                          pacienteId: patient.id,
                          fecha: _appointmentDate.text.trim(),
                          motivo: _appointmentReason.text.trim(),
                          estado: _stateFromText(_appointmentStatus.text.trim()),
                          canalRecordatorio: _appointmentChannel.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Agendar / reprogramar'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...state.appointments.map((item) => Card(
              child: ListTile(
                title: Text(item.fecha),
                subtitle: Text('${item.motivo}\n${item.estado.name} · ${item.canalRecordatorio}'),
              ),
            )),
      ],
    );
  }

  Widget _communicationSection(BuildContext context, NutricionistaState state, NutricionistaController controller) {
    final patient = state.selectedPatient;
    if (patient == null) return const Text('Selecciona un paciente para comunicarte.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comunicación con pacientes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Form(
                  key: _messageFormKey,
                  child: Column(
                    children: [
                      _field(_messageContent, 'Mensaje o recomendación', maxLines: 4, validator: _required),
                      FilledButton(
                        onPressed: () {
                          if (!_messageFormKey.currentState!.validate()) return;
                          controller.addMessage(
                            patient.id,
                            MensajePaciente(
                              id: 0,
                              pacienteId: patient.id,
                              remitente: 'nutricionista',
                              contenido: _messageContent.text.trim(),
                              fecha: _todayTime(),
                            ),
                          );
                          _messageContent.clear();
                        },
                        child: const Text('Enviar chat interno'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: patient.telefono.isEmpty
                      ? null
                      : () => _openWhatsapp(patient.telefono, 'Hola ${patient.nombre}, te escribo desde NNEN.'),
                  child: const Text('Abrir WhatsApp del paciente'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...state.messages.map((message) => Card(
              child: ListTile(
                title: Text(message.remitente),
                subtitle: Text('${message.contenido}\n${message.fecha}'),
              ),
            )),
      ],
    );
  }

  Widget _paymentsSection(BuildContext context, NutricionistaState state, NutricionistaController controller) {
    final patient = state.selectedPatient;
    if (patient == null) return const Text('Selecciona un paciente para registrar pagos.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pagos y facturación', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Form(
          key: _paymentFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _field(_paymentAmount, 'Monto', keyboardType: TextInputType.number, validator: _numberValidator),
                  _field(_paymentConcept, 'Concepto', validator: _required),
                  _field(_paymentStatus, 'Estado', validator: _required),
                  FilledButton(
                    onPressed: () {
                      if (!_paymentFormKey.currentState!.validate()) return;
                      controller.addPayment(
                        patient.id,
                        PagoPaciente(
                          id: 0,
                          pacienteId: patient.id,
                          monto: double.tryParse(_paymentAmount.text.trim()) ?? 0,
                          concepto: _paymentConcept.text.trim(),
                          fecha: _todayTime(),
                          estado: _paymentStatus.text.trim().toUpperCase() == 'PAGADO'
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
          ),
        ),
        const SizedBox(height: 12),
        ...state.payments.map((payment) => Card(
              child: ListTile(
                title: Text('\$${payment.monto.toStringAsFixed(2)}'),
                subtitle: Text('${payment.concepto}\n${payment.estado.name} · ${payment.fecha}'),
              ),
            )),
      ],
    );
  }

  Widget _settingsSection(BuildContext context, NutricionistaState state, NutricionistaController controller) {
    return Form(
      key: _settingsFormKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configuración básica', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _field(_price, 'Precio de consulta', keyboardType: TextInputType.number, validator: _numberValidator),
              _field(_whatsapp, 'WhatsApp profesional', validator: _required),
              FilledButton(
                onPressed: () {
                  if (!_settingsFormKey.currentState!.validate()) return;
                  controller.saveSettings(
                    NutricionistaSettings(
                      precioConsulta: double.tryParse(_price.text.trim()) ?? 0,
                      whatsapp: _whatsapp.text.trim(),
                    ),
                  );
                },
                child: const Text('Guardar configuración'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickPatientPreview(Paciente patient) {
    final imc = _imc(patient.peso, patient.altura);
    final tmb = _tmb(patient.peso, patient.altura * 100, patient.edad, patient.sexo);
    final get = tmb * patient.factorActividad;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista rápida del paciente', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${patient.nombre} · ${patient.correo}'),
            Text('Peso: ${patient.peso.toStringAsFixed(1)} kg'),
            Text('Altura: ${patient.altura.toStringAsFixed(2)} m'),
            Text('Grasa corporal: ${patient.grasaCorporal.toStringAsFixed(1)} %'),
            Text('IMC: ${imc.toStringAsFixed(1)}'),
            Text('TMB: ${tmb.toStringAsFixed(0)}'),
            Text('GET: ${get.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => context.go('/nutricionista/paciente/${patient.id}'),
              child: const Text('Abrir ficha completa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(Paciente patient, NutricionistaController controller, {bool showDetail = false}) {
    final imc = _imc(patient.peso, patient.altura);
    return Card(
      child: ListTile(
        title: Text(patient.nombre),
        subtitle: Text('${patient.correo}\nIMC ${imc.toStringAsFixed(1)} · ${patient.telefono}'),
        isThreeLine: true,
        trailing: showDetail ? const Icon(Icons.chevron_right) : null,
        onTap: () async {
          await controller.selectPatient(patient.id);
          controller.setSection(NutricionistaSection.dashboard);
          if (showDetail) {
            if (!mounted) return;
            context.go('/nutricionista/paciente/${patient.id}');
          }
        },
      ),
    );
  }

  Widget _progressChart(List<Evaluacion> evaluations) {
    if (evaluations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aún no hay evaluaciones para mostrar.'),
        ),
      );
    }

    final ordered = evaluations.reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < ordered.length; i++) {
      spots.add(FlSpot(i.toDouble(), ordered[i].peso));
    }

    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _twoColumn(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(children: children);
        }
        return Wrap(
          spacing: 16,
          runSpacing: 8,
          children: children
              .map(
                (widget) => SizedBox(
                  width: (constraints.maxWidth / 2) - 16,
                  child: widget,
                ),
              )
              .toList(),
        );
      },
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null;
  String? _emailValidator(String? value) =>
      (value == null || !value.contains('@')) ? 'Correo inválido' : null;
  String? _numberValidator(String? value) =>
      double.tryParse((value ?? '').replaceAll(',', '.')) == null ? 'Número inválido' : null;

  void _clearPatientForm() {
    for (final controller in [_name, _email, _weight, _height, _fat, _allergies, _conditions, _phone, _notes]) {
      controller.clear();
    }
    _age.text = '30';
    _sex.text = 'Femenino';
    _activity.text = '1.2';
  }

  void _applyPatientToForm(Paciente patient) {
    _name.text = patient.nombre;
    _email.text = patient.correo;
    _weight.text = patient.peso.toStringAsFixed(1);
    _height.text = patient.altura.toStringAsFixed(2);
    _fat.text = patient.grasaCorporal.toStringAsFixed(1);
    _allergies.text = patient.alergias;
    _conditions.text = patient.enfermedades;
    _age.text = patient.edad.toString();
    _sex.text = patient.sexo;
    _activity.text = patient.factorActividad.toStringAsFixed(2);
    _phone.text = patient.telefono;
    _notes.text = patient.notas;
  }

  double _double(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
  double _imc(double peso, double altura) => altura <= 0 ? 0 : peso / (altura * altura);
  double _tmb(double peso, double alturaCm, int edad, String sexo) {
    final adjust = sexo.toLowerCase().contains('masc') ? 5 : -161;
    return (10 * peso) + (6.25 * alturaCm) - (5 * edad) + adjust;
  }

  CitaEstado _stateFromText(String text) {
    return switch (text.toUpperCase()) {
      'REPROGRAMADA' => CitaEstado.reprogramada,
      'COMPLETADA' => CitaEstado.completada,
      'CANCELADA' => CitaEstado.cancelada,
      _ => CitaEstado.agendada,
    };
  }

  Future<void> _openWhatsapp(String numero, String mensaje) async {
    final uri = Uri.parse('https://wa.me/${numero.replaceAll(RegExp(r'\D'), '')}?text=${Uri.encodeComponent(mensaje)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _todayTime() {
    final now = DateTime.now();
    return '${_today()} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message),
      ),
    );
  }
}
