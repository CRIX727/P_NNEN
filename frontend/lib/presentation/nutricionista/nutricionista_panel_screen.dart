import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/alimento.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/plantilla_plan.dart';
import '../../domain/entities/tarea_nutricionista.dart';
import 'nutricionista_controller.dart';
import 'nutricionista_state.dart';
import 'professional_tools_screen.dart';
import '../shared/sync_status_indicator.dart';

class NutritionistPanelScreen extends ConsumerStatefulWidget {
  const NutritionistPanelScreen({super.key});

  @override
  ConsumerState<NutritionistPanelScreen> createState() =>
      _NutritionistPanelScreenState();
}

class _NutritionistPanelScreenState
    extends ConsumerState<NutritionistPanelScreen> {
  final _drawerKey = GlobalKey<ScaffoldState>();
  final _patientFormKey = GlobalKey<FormState>();
  final _planFormKey = GlobalKey<FormState>();
  final _appointmentFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _templateFormKey = GlobalKey<FormState>();
  final _settingsFormKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _invitationEmail = TextEditingController();
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
  final _reason = TextEditingController();
  final _familyHistory = TextEditingController();
  final _medicalHistory = TextEditingController();
  final _medications = TextEditingController();
  final _eatingHabits = TextEditingController();
  final _water = TextEditingController();
  final _activityHabits = TextEditingController();
  final _objectives = TextEditingController();
  final _privateNotes = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();
  final _arm = TextEditingController();
  final _skinfolds = TextEditingController();
  final _muscle = TextEditingController();
  final _patientSearch = TextEditingController();

  final _evaluationWeight = TextEditingController();
  final _evaluationHeight = TextEditingController();
  final _evaluationFat = TextEditingController();

  final _planTitle = TextEditingController(text: 'Plan general');
  final _planObjective = TextEditingController();
  final _planCondition = TextEditingController();
  final _planDescription = TextEditingController();
  final _planMeals = TextEditingController();
  final _planSubstitutions = TextEditingController();
  final _planCalories = TextEditingController();
  final _planProtein = TextEditingController();
  final _planCarbs = TextEditingController();
  final _planFat = TextEditingController();
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
  DateTime? _agendaDay;
  bool _onlyRiskPatients = false;
  String _objectiveFilter = '';

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
      _invitationEmail,
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
      _reason,
      _familyHistory,
      _medicalHistory,
      _medications,
      _eatingHabits,
      _water,
      _activityHabits,
      _objectives,
      _privateNotes,
      _waist,
      _hip,
      _arm,
      _skinfolds,
      _muscle,
      _patientSearch,
      _evaluationWeight,
      _evaluationHeight,
      _evaluationFat,
      _planTitle,
      _planObjective,
      _planCondition,
      _planDescription,
      _planMeals,
      _planSubstitutions,
      _planCalories,
      _planProtein,
      _planCarbs,
      _planFat,
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

    if (state.selectedPatient != null &&
        state.selectedPatient!.id != _lastAppliedPatientId) {
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
          const SyncStatusIndicator(),
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
              _drawerItem(state, NutricionistaSection.dashboard, 'Dashboard',
                  Icons.dashboard),
              _drawerItem(state, NutricionistaSection.agregarPaciente,
                  'Agregar paciente', Icons.person_add),
              _drawerItem(state, NutricionistaSection.misPacientes,
                  'Mis pacientes', Icons.people),
              _drawerItem(state, NutricionistaSection.planes,
                  'Planes alimenticios', Icons.restaurant_menu),
              _drawerItem(state, NutricionistaSection.agenda, 'Agenda y citas',
                  Icons.calendar_month),
              _drawerItem(state, NutricionistaSection.comunicacion,
                  'Comunicación', Icons.chat),
              _drawerItem(state, NutricionistaSection.pagos,
                  'Pagos y facturación', Icons.payments),
              _drawerItem(state, NutricionistaSection.herramientas,
                  'Herramientas profesionales', Icons.calculate_outlined),
              _drawerItem(state, NutricionistaSection.configuracion,
                  'Configuración', Icons.settings),
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
                  if (state.message != null)
                    _InfoBanner(message: state.message!),
                  if (state.section == NutricionistaSection.dashboard) ...[
                    _buildHeader(state),
                    const SizedBox(height: 16),
                  ],
                  switch (state.section) {
                    NutricionistaSection.dashboard =>
                      _dashboardSection(context, state, controller),
                    NutricionistaSection.agregarPaciente =>
                      _addPatientSection(context, state, controller),
                    NutricionistaSection.misPacientes =>
                      _patientsSection(context, state, controller),
                    NutricionistaSection.planes =>
                      _plansSection(context, state, controller),
                    NutricionistaSection.agenda =>
                      _appointmentsSection(context, state, controller),
                    NutricionistaSection.comunicacion =>
                      _communicationSection(context, state, controller),
                    NutricionistaSection.pagos =>
                      _paymentsSection(context, state, controller),
                    NutricionistaSection.herramientas =>
                      ProfessionalToolsScreen(
                          state: state, controller: controller),
                    NutricionistaSection.configuracion =>
                      _settingsSection(context, state, controller),
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
      leading: Icon(icon,
          color: selected ? Theme.of(context).colorScheme.primary : null),
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
                  _metric(
                      'Pagos pendientes', summary.pagosPendientes.toString()),
                  _metric(
                      'IMC promedio', summary.imcPromedio.toStringAsFixed(1)),
                  _metric(
                      'Pacientes nuevos', summary.pacientesNuevos.toString()),
                  _metric('Pacientes en riesgo',
                      summary.pacientesEnRiesgo.toString()),
                  _metric('Citas próximas', summary.citasProximas.toString()),
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
    final patient = state.selectedPatient ??
        (state.pacientes.isNotEmpty ? state.pacientes.first : null);
    final evaluations = state.evaluations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pacientes recientes',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...state.pacientes.take(5).map((p) => _patientCard(p, controller)),
        const SizedBox(height: 20),
        _riskAlerts(state.pacientes),
        const SizedBox(height: 20),
        _tasksCard(state, controller),
        const SizedBox(height: 20),
        Text('Evolución clínica',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _progressChart(evaluations),
        const SizedBox(height: 20),
        if (patient != null) _quickPatientPreview(patient),
      ],
    );
  }

  Widget _addPatientSection(BuildContext context, NutricionistaState state,
      NutricionistaController controller) {
    return Form(
      key: _patientFormKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invitar paciente',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      const Text(
                          'El paciente puede crear su cuenta por separado y aceptar la invitación desde su aplicación.'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _invitationEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            labelText: 'Correo del paciente'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: state.loading
                            ? null
                            : () {
                                if (_invitationEmail.text.trim().isEmpty) {
                                  return;
                                }
                                controller
                                    .createInvitation(_invitationEmail.text);
                                _invitationEmail.clear();
                              },
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Enviar invitación'),
                      ),
                      if (state.invitations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Invitaciones enviadas',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ...state.invitations
                            .take(5)
                            .map((invitation) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                      Icons.mark_email_read_outlined),
                                  title: Text(invitation.correo),
                                  subtitle: Text(invitation.estado),
                                )),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Agregar paciente completo',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _twoColumn([
                _field(_name, 'Nombre completo', validator: _required),
                _field(_email, 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator),
                _field(_weight, 'Peso (kg)',
                    keyboardType: TextInputType.number,
                    validator: _numberValidator),
                _field(_height, 'Altura (m)',
                    keyboardType: TextInputType.number,
                    validator: _numberValidator),
                _field(_fat, 'Grasa corporal %',
                    keyboardType: TextInputType.number,
                    validator: _numberValidator),
                _field(_age, 'Edad',
                    keyboardType: TextInputType.number,
                    validator: _numberValidator),
                _field(_sex, 'Sexo', validator: _required),
                _field(_activity, 'Factor actividad',
                    keyboardType: TextInputType.number,
                    validator: _numberValidator),
                _field(_phone, 'WhatsApp / Teléfono'),
                _field(_allergies, 'Alergias'),
                _field(_conditions, 'Enfermedades'),
                _field(_reason, 'Motivo de consulta', maxLines: 2),
                _field(_familyHistory, 'Antecedentes familiares', maxLines: 2),
                _field(_medicalHistory, 'Historial médico', maxLines: 2),
                _field(_medications, 'Medicamentos', maxLines: 2),
                _field(_eatingHabits, 'Hábitos alimenticios', maxLines: 2),
                _field(_water, 'Consumo de agua'),
                _field(_activityHabits, 'Actividad física'),
                _field(_objectives, 'Objetivos del paciente', maxLines: 2),
                _field(_waist, 'Cintura (cm)',
                    keyboardType: TextInputType.number),
                _field(_hip, 'Cadera (cm)', keyboardType: TextInputType.number),
                _field(_arm, 'Brazo (cm)', keyboardType: TextInputType.number),
                _field(_skinfolds, 'Pliegues cutáneos', maxLines: 2),
                _field(_muscle, '% músculo',
                    keyboardType: TextInputType.number),
                _field(_notes, 'Notas públicas', maxLines: 2),
                _field(_privateNotes, 'Notas privadas', maxLines: 2),
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
                    motivoConsulta: _reason.text.trim(),
                    antecedentesFamiliares: _familyHistory.text.trim(),
                    historialMedico: _medicalHistory.text.trim(),
                    medicamentos: _medications.text.trim(),
                    habitosAlimenticios: _eatingHabits.text.trim(),
                    consumoAgua: _water.text.trim(),
                    actividadFisica: _activityHabits.text.trim(),
                    objetivos: _objectives.text.trim(),
                    notasPrivadas: _privateNotes.text.trim(),
                    cintura: _double(_waist),
                    cadera: _double(_hip),
                    brazo: _double(_arm),
                    plieguesCutaneos: _skinfolds.text.trim(),
                    porcentajeMusculo: _double(_muscle),
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

  Widget _patientsSection(BuildContext context, NutricionistaState state,
      NutricionistaController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis pacientes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _patientSearch,
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre, correo o condición',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Solo pacientes en riesgo'),
              selected: _onlyRiskPatients,
              onSelected: (value) => setState(() => _onlyRiskPatients = value),
            ),
            DropdownButton<String>(
              value: _objectiveFilter.isEmpty ? null : _objectiveFilter,
              hint: const Text('Filtrar objetivo'),
              items: const [
                DropdownMenuItem(value: 'bajar', child: Text('Bajar peso')),
                DropdownMenuItem(value: 'masa', child: Text('Masa muscular')),
                DropdownMenuItem(value: 'clinico', child: Text('Clínico')),
              ],
              onChanged: (value) =>
                  setState(() => _objectiveFilter = value ?? ''),
            ),
            if (_objectiveFilter.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _objectiveFilter = ''),
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.pacientes.where((p) {
          final query = _patientSearch.text.trim().toLowerCase();
          final conditions = p.enfermedades.toLowerCase();
          final risk =
              ['diabet', 'hipertens', 'obes', 'renal'].any(conditions.contains);
          final objective = p.objetivos.toLowerCase();
          final objectiveMatches =
              _objectiveFilter.isEmpty || objective.contains(_objectiveFilter);
          return (!_onlyRiskPatients || risk) &&
              objectiveMatches &&
              (query.isEmpty ||
                  p.nombre.toLowerCase().contains(query) ||
                  p.correo.toLowerCase().contains(query) ||
                  conditions.contains(query));
        }).map((p) => _patientCard(p, controller, showDetail: true)),
      ],
    );
  }

  Widget _plansSection(BuildContext context, NutricionistaState state,
      NutricionistaController controller) {
    final patient = state.selectedPatient;
    if (patient == null) {
      return const Text(
          'Selecciona un paciente para crear y reutilizar planes.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Planes alimenticios',
            style: Theme.of(context).textTheme.titleLarge),
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
                  _field(_planDescription, 'Descripción',
                      maxLines: 4, validator: _required),
                  _twoColumn([
                    _field(_planStart, 'Fecha inicio', validator: _required),
                    _field(_planEnd, 'Fecha fin', validator: _required),
                  ]),
                  _field(_planMeals,
                      'Comidas y distribución (desayuno, almuerzo, cena, meriendas)',
                      maxLines: 4),
                  _field(_planSubstitutions, 'Sustituciones', maxLines: 3),
                  _twoColumn([
                    _field(_planCalories, 'Calorías',
                        keyboardType: TextInputType.number),
                    _field(_planProtein, 'Proteínas (g)',
                        keyboardType: TextInputType.number),
                    _field(_planCarbs, 'Carbohidratos (g)',
                        keyboardType: TextInputType.number),
                    _field(_planFat, 'Grasas (g)',
                        keyboardType: TextInputType.number),
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
                          titulo: _planTitle.text.trim().isEmpty
                              ? 'Plan general'
                              : _planTitle.text.trim(),
                          descripcion: _planDescription.text.trim(),
                          objetivo: _planObjective.text.trim(),
                          condicion: _planCondition.text.trim(),
                          plantillaNombre: state.templates.isNotEmpty
                              ? state.templates.first.nombre
                              : '',
                          fechaInicio: _planStart.text.trim(),
                          fechaFin: _planEnd.text.trim(),
                          comidas: _planMeals.text.trim(),
                          sustituciones: _planSubstitutions.text.trim(),
                          calorias: _double(_planCalories),
                          proteinas: _double(_planProtein),
                          carbohidratos: _double(_planCarbs),
                          grasasMacros: _double(_planFat),
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
                subtitle: Text(
                    '${plan.objetivo} · ${plan.condicion}\n${plan.descripcion}'),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Editar plan',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _showPlanEditor(context, patient, controller, plan),
                ),
              ),
            )),
        const SizedBox(height: 16),
        _foodDatabaseCard(state.foods),
        const SizedBox(height: 16),
        Form(
          key: _templateFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Crear plantilla',
                      style: Theme.of(context).textTheme.titleMedium),
                  _field(_templateName, 'Nombre plantilla',
                      validator: _required),
                  _field(_templateObjective, 'Objetivo'),
                  _field(_templateCondition, 'Condición'),
                  _field(_templateDescription, 'Descripción',
                      maxLines: 4, validator: _required),
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

  Widget _foodDatabaseCard(List<Alimento> storedFoods) {
    final catalog = storedFoods.isNotEmpty
        ? storedFoods
        : const [
            Alimento(
                id: 0,
                nombre: 'Avena',
                porcion: '40 g',
                calorias: 150,
                proteinas: 5,
                carbohidratos: 27,
                grasas: 3),
            Alimento(
                id: 0,
                nombre: 'Huevo',
                porcion: '1 unidad',
                calorias: 78,
                proteinas: 6,
                carbohidratos: 1,
                grasas: 5),
            Alimento(
                id: 0,
                nombre: 'Pechuga de pollo',
                porcion: '100 g',
                calorias: 165,
                proteinas: 31,
                carbohidratos: 0,
                grasas: 3.6),
          ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base de datos de alimentos',
                style: Theme.of(context).textTheme.titleMedium),
            const Text(
                'Toca un alimento para añadirlo al plan y calcular sus macros.'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: catalog
                  .map((food) => ActionChip(
                        label: Text('${food.nombre} (${food.porcion})'),
                        onPressed: () {
                          _planCalories.text =
                              (_double(_planCalories) + food.calorias)
                                  .toStringAsFixed(0);
                          _planProtein.text =
                              (_double(_planProtein) + food.proteinas)
                                  .toStringAsFixed(1);
                          _planCarbs.text =
                              (_double(_planCarbs) + food.carbohidratos)
                                  .toStringAsFixed(1);
                          _planFat.text = (_double(_planFat) + food.grasas)
                              .toStringAsFixed(1);
                          _planMeals.text = _planMeals.text.isEmpty
                              ? '${food.nombre} (${food.porcion})'
                              : '${_planMeals.text}\n${food.nombre} (${food.porcion})';
                          setState(() {});
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentsSection(BuildContext context, NutricionistaState state,
      NutricionistaController controller) {
    final patient = state.selectedPatient;
    if (patient == null) {
      return const Text('Selecciona un paciente para agendar citas.');
    }
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
                  _dateTimeField(_appointmentDate, 'Fecha y hora',
                      validator: _required),
                  _field(_appointmentReason, 'Motivo', validator: _required),
                  _field(_appointmentStatus, 'Estado', validator: _required),
                  _field(_appointmentChannel, 'Canal de recordatorio',
                      validator: _required),
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
                          estado:
                              _stateFromText(_appointmentStatus.text.trim()),
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
        _agendaCalendar(context, state),
        const SizedBox(height: 12),
        ...state.appointments.map((item) => Card(
              child: ListTile(
                title: Text(item.fecha),
                subtitle: Text(
                    '${item.motivo}\n${item.estado.name} · ${item.canalRecordatorio}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'editar') {
                      _showAppointmentEditor(
                          context, patient, controller, item);
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
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: 'editar', child: Text('Editar / reprogramar')),
                    PopupMenuItem(
                        value: 'cancelar', child: Text('Cancelar cita')),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _agendaCalendar(BuildContext context, NutricionistaState state) {
    final appointments = state.appointments
        .map((item) => (item: item, date: _parseDate(item.fecha)))
        .where((entry) => entry.date != null)
        .toList();
    final markedDays = appointments
        .map((entry) =>
            DateTime(entry.date!.year, entry.date!.month, entry.date!.day))
        .toSet();
    final selected = _agendaDay ?? DateTime.now();
    final selectedAppointments = appointments
        .where((entry) => _sameDay(entry.date!, selected))
        .map((entry) => entry.item)
        .toList();
    final past = appointments
        .where((entry) => entry.date!.isBefore(DateTime.now()))
        .map((entry) => entry.item)
        .where((item) => item.estado != CitaEstado.cancelada)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calendario de citas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Los días con un punto tienen citas registradas.'),
            CalendarDatePicker(
              initialDate: selected,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              onDateChanged: (date) => setState(() => _agendaDay = date),
              selectableDayPredicate: (date) => true,
            ),
            if (markedDays.any((day) => _sameDay(day, selected)))
              Text('Citas del ${_formatDay(selected)}',
                  style: Theme.of(context).textTheme.titleSmall),
            if (selectedAppointments.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No hay citas para este día.'),
              )
            else
              ...selectedAppointments.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(item.fecha),
                    subtitle: Text('${item.motivo} · ${item.estado.name}'),
                  )),
            const Divider(),
            Text('Historial de citas',
                style: Theme.of(context).textTheme.titleSmall),
            if (past.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Todavía no hay citas anteriores.'),
              )
            else
              ...past.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: Text(item.fecha),
                    subtitle: Text(item.motivo),
                  )),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDate(String value) =>
      DateTime.tryParse(value.replaceFirst(' ', 'T'));

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _formatDay(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Widget _communicationSection(BuildContext context, NutricionistaState state,
      NutricionistaController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comunicación con pacientes',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Toca un paciente para abrir su conversación.'),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(child: Icon(Icons.people_outline)),
                title: Text('Mis conversaciones'),
                subtitle: Text(
                    'Mensajes y recomendaciones${state.unreadMessages > 0 ? ' · ${state.unreadMessages} sin leer' : ''}'),
              ),
              ...state.pacientes.map((item) => ListTile(
                    leading: CircleAvatar(
                        child: Text(item.nombre.isEmpty
                            ? '?'
                            : item.nombre.substring(0, 1).toUpperCase())),
                    title: Text(item.nombre),
                    subtitle: Text(item.correo),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openNutritionistChat(context, item.id),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openNutritionistChat(
      BuildContext context, int patientId) async {
    final controller = ref.read(nutritionistControllerProvider);
    await controller.selectPatient(patientId);
    if (!mounted) return;
    final patient = controller.state.pacientes.firstWhere(
      (item) => item.id == patientId,
      orElse: () => controller.state.selectedPatient!,
    );
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NutritionistChatScreen(patient: patient),
      ),
    );
  }

  Widget _paymentsSection(BuildContext context, NutricionistaState state,
      NutricionistaController controller) {
    final patient = state.selectedPatient;
    if (patient == null) {
      return const Text('Selecciona un paciente para registrar pagos.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pagos y facturación',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Form(
          key: _paymentFormKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _field(_paymentAmount, 'Monto',
                      keyboardType: TextInputType.number,
                      validator: _numberValidator),
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
                          monto:
                              double.tryParse(_paymentAmount.text.trim()) ?? 0,
                          concepto: _paymentConcept.text.trim(),
                          fecha: _todayTime(),
                          estado: _paymentStatus.text.trim().toUpperCase() ==
                                  'PAGADO'
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
                subtitle: Text(
                    '${payment.concepto}\n${payment.estado.name} · ${payment.fecha}'),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Editar pago',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _showPaymentEditor(context, patient, controller, payment),
                ),
              ),
            )),
      ],
    );
  }

  Widget _settingsSection(BuildContext context, NutricionistaState state,
      NutricionistaController controller) {
    return Form(
      key: _settingsFormKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configuración básica',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _field(_price, 'Precio de consulta',
                  keyboardType: TextInputType.number,
                  validator: _numberValidator),
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
                _dateTimeField(date, 'Fecha y hora',
                    onPicked: () => setState(() {})),
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

  Widget _dateTimeField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    VoidCallback? onPicked,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: validator,
        decoration: InputDecoration(
            labelText: label, suffixIcon: const Icon(Icons.calendar_month)),
        onTap: () async {
          final current =
              DateTime.tryParse(controller.text.replaceFirst(' ', 'T')) ??
                  DateTime.now();
          final date = await showDatePicker(
            context: context,
            initialDate: current,
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date == null || !mounted) return;
          final time = await showTimePicker(
              context: context, initialTime: TimeOfDay.fromDateTime(current));
          if (time == null) return;
          controller.text =
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onPicked?.call();
        },
      ),
    );
  }

  Widget _quickPatientPreview(Paciente patient) {
    final imc = _imc(patient.peso, patient.altura);
    final tmb =
        _tmb(patient.peso, patient.altura * 100, patient.edad, patient.sexo);
    final get = tmb * patient.factorActividad;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista rápida del paciente',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${patient.nombre} · ${patient.correo}'),
            Text('Peso: ${patient.peso.toStringAsFixed(1)} kg'),
            Text('Altura: ${patient.altura.toStringAsFixed(2)} m'),
            Text(
                'Grasa corporal: ${patient.grasaCorporal.toStringAsFixed(1)} %'),
            Text('IMC: ${imc.toStringAsFixed(1)}'),
            Text('TMB: ${tmb.toStringAsFixed(0)}'),
            Text('GET: ${get.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () =>
                  context.go('/nutricionista/paciente/${patient.id}'),
              child: const Text('Abrir ficha completa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(Paciente patient, NutricionistaController controller,
      {bool showDetail = false}) {
    final imc = _imc(patient.peso, patient.altura);
    return Card(
      child: ListTile(
        title: Text(patient.nombre),
        subtitle: Text(
            '${patient.correo}\nIMC ${imc.toStringAsFixed(1)} · ${patient.telefono}'),
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

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null;
  String? _emailValidator(String? value) =>
      (value == null || !value.contains('@')) ? 'Correo inválido' : null;
  String? _numberValidator(String? value) =>
      double.tryParse((value ?? '').replaceAll(',', '.')) == null
          ? 'Número inválido'
          : null;

  void _clearPatientForm() {
    for (final controller in [
      _name,
      _email,
      _weight,
      _height,
      _fat,
      _allergies,
      _conditions,
      _phone,
      _notes,
      _reason,
      _familyHistory,
      _medicalHistory,
      _medications,
      _eatingHabits,
      _water,
      _activityHabits,
      _objectives,
      _privateNotes,
      _waist,
      _hip,
      _arm,
      _skinfolds,
      _muscle,
    ]) {
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
    _reason.text = patient.motivoConsulta;
    _familyHistory.text = patient.antecedentesFamiliares;
    _medicalHistory.text = patient.historialMedico;
    _medications.text = patient.medicamentos;
    _eatingHabits.text = patient.habitosAlimenticios;
    _water.text = patient.consumoAgua;
    _activityHabits.text = patient.actividadFisica;
    _objectives.text = patient.objetivos;
    _privateNotes.text = patient.notasPrivadas;
    _waist.text = patient.cintura.toStringAsFixed(1);
    _hip.text = patient.cadera.toStringAsFixed(1);
    _arm.text = patient.brazo.toStringAsFixed(1);
    _skinfolds.text = patient.plieguesCutaneos;
    _muscle.text = patient.porcentajeMusculo.toStringAsFixed(1);
  }

  Widget _riskAlerts(List<Paciente> patients) {
    final atRisk = patients.where((patient) {
      final conditions = patient.enfermedades.toLowerCase();
      return conditions.contains('diabet') ||
          conditions.contains('hipertens') ||
          conditions.contains('obes') ||
          conditions.contains('renal');
    }).toList();
    if (atRisk.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alertas de seguimiento',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...atRisk.map((patient) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(patient.nombre),
                  subtitle: Text(patient.enfermedades),
                )),
          ],
        ),
      ),
    );
  }

  Widget _tasksCard(
      NutricionistaState state, NutricionistaController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Tareas pendientes',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: 'Nueva tarea',
                  onPressed: () => _showTaskEditor(controller),
                  icon: const Icon(Icons.add_task),
                ),
              ],
            ),
            if (state.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('No hay tareas pendientes.'),
              ),
            ...state.tasks.map((task) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: task.completada,
                  title: Text(task.titulo),
                  subtitle: task.fechaLimite.isEmpty
                      ? null
                      : Text('Límite: ${task.fechaLimite}'),
                  onChanged: (value) => controller.updateTask(
                    TareaNutricionista(
                      id: task.id,
                      titulo: task.titulo,
                      descripcion: task.descripcion,
                      fechaLimite: task.fechaLimite,
                      completada: value ?? false,
                      pacienteId: task.pacienteId,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _showTaskEditor(NutricionistaController controller) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final dueDate = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva tarea'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe un título'
                    : null,
              ),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextFormField(
                controller: dueDate,
                decoration: const InputDecoration(
                    labelText: 'Fecha límite (AAAA-MM-DD)'),
              ),
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
              if (!formKey.currentState!.validate()) return;
              controller.createTask(TareaNutricionista(
                id: 0,
                titulo: title.text.trim(),
                descripcion: description.text.trim(),
                fechaLimite: dueDate.text.trim(),
                completada: false,
              ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    title.dispose();
    description.dispose();
    dueDate.dispose();
  }

  double _double(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
  double _imc(double peso, double altura) =>
      altura <= 0 ? 0 : peso / (altura * altura);
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

class NutritionistChatScreen extends ConsumerStatefulWidget {
  const NutritionistChatScreen({super.key, required this.patient});

  final Paciente patient;

  @override
  ConsumerState<NutritionistChatScreen> createState() =>
      _NutritionistChatScreenState();
}

class _NutritionistChatScreenState
    extends ConsumerState<NutritionistChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(nutritionistControllerProvider);
    final messages = controller.state.selectedPatient?.id == widget.patient.id
        ? controller.state.messages
        : const <MensajePaciente>[];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(widget.patient.nombre.isEmpty
                  ? '?'
                  : widget.patient.nombre.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  Text(widget.patient.nombre, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Aún no hay mensajes.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _messageBubble(
                        context, messages[index], 'nutricionista'),
                  ),
          ),
          _composer(context, controller),
        ],
      ),
    );
  }

  Widget _messageBubble(
      BuildContext context, MensajePaciente message, String sender) {
    final mine = message.remitente == sender;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.contenido),
            const SizedBox(height: 3),
            Text(message.fecha, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _composer(BuildContext context, NutricionistaController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje',
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Enviar mensaje',
              onPressed: controller.state.loading
                  ? null
                  : () async {
                      final content = _messageController.text.trim();
                      if (content.isEmpty) return;
                      await controller.addMessage(
                        widget.patient.id,
                        MensajePaciente(
                          id: 0,
                          pacienteId: widget.patient.id,
                          remitente: 'nutricionista',
                          contenido: content,
                          fecha: _chatTime(),
                        ),
                      );
                      _messageController.clear();
                    },
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  String _chatTime() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
