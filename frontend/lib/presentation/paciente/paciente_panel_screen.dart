import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/reminder_service.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/paciente_profile.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/consulta.dart';
import 'paciente_controller.dart';
import 'paciente_state.dart';
import '../shared/sync_status_indicator.dart';

class PacientePanelScreen extends ConsumerStatefulWidget {
  const PacientePanelScreen({super.key});

  @override
  ConsumerState<PacientePanelScreen> createState() =>
      _PacientePanelScreenState();
}

class _PacientePanelScreenState extends ConsumerState<PacientePanelScreen> {
  final _messageController = TextEditingController();
  final _reminderService = ReminderService.instance;
  final _activeReminderIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientControllerProvider).load();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(patientControllerProvider);
    final state = controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NNEN · Paciente'),
        actions: [
          const SyncStatusIndicator(),
          IconButton(
            tooltip: 'Actualizar información',
            onPressed: state.isLoading ? null : controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: _buildDrawer(context, state, controller),
      body: state.isLoading && state.profile == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.profile == null
              ? _errorView(state.error!, controller)
              : _buildContent(context, state, controller),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    PacienteState state,
    PacienteController controller,
  ) {
    final name = state.profile?.paciente.nombre ?? 'Paciente';
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NNEN',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(letterSpacing: 4)),
                  const SizedBox(height: 12),
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  const Text('Panel del paciente'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _menuItem(context, controller, PacienteSection.resumen,
                      Icons.home_outlined, 'Resumen'),
                  _menuItem(context, controller, PacienteSection.perfil,
                      Icons.person_outline, 'Mi perfil'),
                  _menuItem(context, controller, PacienteSection.planes,
                      Icons.restaurant_menu, 'Mi plan alimenticio'),
                  _menuItem(context, controller, PacienteSection.progreso,
                      Icons.show_chart, 'Mi progreso'),
                  _menuItem(context, controller, PacienteSection.citas,
                      Icons.calendar_month_outlined, 'Citas y recordatorios'),
                  _menuItem(context, controller, PacienteSection.comunicacion,
                      Icons.chat_bubble_outline, 'Comunicación'),
                  _menuItem(context, controller, PacienteSection.historial,
                      Icons.history, 'Historial de consultas'),
                  _menuItem(context, controller, PacienteSection.pagos,
                      Icons.receipt_long_outlined, 'Pagos'),
                  _menuItem(context, controller, PacienteSection.configuracion,
                      Icons.settings_outlined, 'Configuración'),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => ref.read(authControllerProvider).logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    PacienteController controller,
    PacienteSection section,
    IconData icon,
    String label,
  ) {
    final selected = controller.state.section == section;
    return ListTile(
      selected: selected,
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        controller.setSection(section);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildContent(BuildContext context, PacienteState state,
      PacienteController controller) {
    final content = switch (state.section) {
      PacienteSection.resumen => _summary(context, state),
      PacienteSection.perfil => _profile(context, state),
      PacienteSection.planes => _plans(context, state.planes),
      PacienteSection.progreso => _progress(context, state),
      PacienteSection.citas => _appointments(context, state.citas),
      PacienteSection.comunicacion =>
        _communication(context, state, controller),
      PacienteSection.historial => _history(context, state),
      PacienteSection.pagos => _payments(context, state),
      PacienteSection.configuracion => _settings(context),
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (state.error != null) _messageBanner(state.error!, true),
          if (state.message != null) _messageBanner(state.message!, false),
          if (state.invitations.isNotEmpty) ...[
            _invitationsCard(context, state, controller),
            const SizedBox(height: 16),
          ],
          content,
        ],
      ),
    );
  }

  Widget _summary(BuildContext context, PacienteState state) {
    final patient = state.profile!.paciente;
    final metrics = _metrics(patient);
    final next = state.citas.isEmpty ? null : state.citas.first;
    return _page(
      context,
      'Hola, ${patient.nombre}',
      'Aquí puedes consultar tu información, planes y evolución.',
      [
        _metricGrid([
          _metric('IMC actual', metrics.imc.toStringAsFixed(1),
              Icons.monitor_weight_outlined),
          _metric('TMB', '${metrics.tmb.toStringAsFixed(0)} kcal',
              Icons.local_fire_department_outlined),
          _metric('GET', '${metrics.get.toStringAsFixed(0)} kcal',
              Icons.bolt_outlined),
          _metric(
              'Grasa corporal',
              '${patient.grasaCorporal.toStringAsFixed(1)} %',
              Icons.pie_chart_outline),
        ]),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(next == null
                ? 'Sin citas próximas'
                : 'Próxima cita: ${next.fecha}'),
            subtitle: Text(next == null
                ? 'Cuando tu nutricionista agende una cita aparecerá aquí.'
                : next.motivo),
          ),
        ),
        if (state.notificaciones.any((item) => !item.leida)) ...[
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: state.notificaciones
                  .where((item) => !item.leida)
                  .take(3)
                  .map((item) => ListTile(
                        leading: const Icon(Icons.notifications_active),
                        title: Text(item.titulo),
                        subtitle: Text(item.contenido),
                      ))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _reminders(context, state),
        const SizedBox(height: 18),
        _plansPreview(context, state.planes),
      ],
    );
  }

  Widget _profile(BuildContext context, PacienteState state) {
    final patient = state.profile!.paciente;
    final metrics = _metrics(patient);
    return _page(context, 'Mi perfil',
        'Estos datos fueron registrados por tu nutricionista.', [
      _readOnlyCard('Datos personales', [
        _field('Nombre', patient.nombre),
        _field('Correo', patient.correo),
        _field('Edad', '${patient.edad} años'),
        _field('Sexo', patient.sexo),
        _field('Teléfono',
            patient.telefono.isEmpty ? 'No registrado' : patient.telefono),
      ]),
      const SizedBox(height: 16),
      _readOnlyCard('Datos nutricionales', [
        _field('Peso', '${patient.peso.toStringAsFixed(1)} kg'),
        _field('Altura', '${patient.altura.toStringAsFixed(2)} m'),
        _field(
            'Grasa corporal', '${patient.grasaCorporal.toStringAsFixed(1)} %'),
        _field('IMC',
            '${metrics.imc.toStringAsFixed(1)} · ${_imcLabel(metrics.imc)}'),
        _field('TMB', '${metrics.tmb.toStringAsFixed(0)} kcal/día'),
        _field('GET', '${metrics.get.toStringAsFixed(0)} kcal/día'),
        _field('Alergias',
            patient.alergias.isEmpty ? 'No registradas' : patient.alergias),
        _field(
            'Enfermedades',
            patient.enfermedades.isEmpty
                ? 'No registradas'
                : patient.enfermedades),
      ]),
      const SizedBox(height: 16),
      _readOnlyCard('Mi nutricionista', [
        _field('Nombre', state.profile!.nutricionistaNombre),
        _field('Correo', state.profile!.nutricionistaCorreo),
      ]),
    ]);
  }

  Widget _plans(BuildContext context, List<PlanAlimenticio> plans) {
    return _page(context, 'Mi plan alimenticio',
        'Consulta las indicaciones compartidas contigo.', [
      if (plans.isEmpty) _empty('Aún no tienes planes alimenticios asignados.'),
      ...plans.map(_planCard),
    ]);
  }

  Widget _progress(BuildContext context, PacienteState state) {
    final evaluations = state.evaluaciones;
    return _page(context, 'Mi progreso',
        'Compara tus evaluaciones a lo largo del tiempo.', [
      if (evaluations.isEmpty) _empty('Aún no hay evaluaciones para mostrar.'),
      if (evaluations.isNotEmpty) _progressChart(context, evaluations),
      const SizedBox(height: 16),
      ...evaluations.reversed.map((item) => _evaluationTile(item)),
    ]);
  }

  Widget _appointments(BuildContext context, List<CitaPaciente> appointments) {
    return _page(context, 'Citas y recordatorios',
        'Aquí aparecerán tus consultas programadas.', [
      if (appointments.isEmpty) _empty('No tienes citas registradas.'),
      ...appointments.map((appointment) => Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(appointment.fecha),
              subtitle: Text(
                  '${appointment.motivo}\nRecordatorio: ${appointment.canalRecordatorio}'),
              isThreeLine: true,
              trailing:
                  Chip(label: Text(_appointmentLabel(appointment.estado))),
              onTap: () => _showAppointmentDetails(appointment),
            ),
          )),
    ]);
  }

  Widget _communication(BuildContext context, PacienteState state,
      PacienteController controller) {
    final profile = state.profile!;
    return _page(
        context, 'Comunicación', 'Toca el contacto para abrir el chat.', [
      Card(
        child: ListTile(
          leading: CircleAvatar(
              child: Text(profile.nutricionistaNombre.isEmpty
                  ? '?'
                  : profile.nutricionistaNombre.substring(0, 1).toUpperCase())),
          title: Text(profile.nutricionistaNombre),
          subtitle: Text(profile.nutricionistaCorreo),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openPatientChat(context, profile),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Chat privado'),
          subtitle: Text(state.mensajes.isEmpty
              ? 'Aún no hay mensajes.'
              : '${state.mensajes.length} mensajes${state.unreadMessages > 0 ? ' · ${state.unreadMessages} sin leer' : ''}'),
          trailing: profile.nutricionistaWhatsapp.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Abrir WhatsApp',
                  icon: const Icon(Icons.phone),
                  onPressed: () => _openWhatsapp(profile.nutricionistaWhatsapp),
                ),
        ),
      ),
    ]);
  }

  Future<void> _openPatientChat(
      BuildContext context, PacienteProfile profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientChatScreen(profile: profile),
      ),
    );
  }

  Widget _history(BuildContext context, PacienteState state) {
    return _page(context, 'Historial de consultas',
        'Consulta tus citas y evaluaciones anteriores.', [
      if (state.citas.isNotEmpty) ...[
        Text('Citas anteriores', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...state.citas
            .where((cita) => _isPast(cita.fecha))
            .map((appointment) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_available_outlined),
                    title: Text(appointment.fecha),
                    subtitle: Text(appointment.motivo),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAppointmentDetails(appointment),
                  ),
                )),
        const SizedBox(height: 16),
      ],
      if (state.evaluaciones.isEmpty && state.citas.isEmpty)
        _empty('No hay consultas registradas.'),
      if (state.consultas.isNotEmpty) ...[
        Text('Consultas clínicas',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...state.consultas.map((consultation) => Card(
              child: ListTile(
                leading: const Icon(Icons.medical_information_outlined),
                title: Text(consultation.fecha),
                subtitle: Text(
                    '${consultation.motivo.isEmpty ? 'Consulta nutricional' : consultation.motivo}\n${consultation.notas}'),
                isThreeLine: true,
                onTap: () => _showConsultationDetails(consultation),
              ),
            )),
      ],
      ...state.evaluaciones.reversed.map((evaluation) => Card(
            child: ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text('Consulta del ${evaluation.fecha}'),
              subtitle: Text(
                'Peso: ${evaluation.peso.toStringAsFixed(1)} kg · '
                'Altura: ${evaluation.altura.toStringAsFixed(2)} m\n'
                'IMC: ${evaluation.imc.toStringAsFixed(1)} · '
                'TMB: ${evaluation.tmb.toStringAsFixed(0)} · '
                'GET: ${evaluation.get.toStringAsFixed(0)}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEvaluationDetails(evaluation),
            ),
          )),
    ]);
  }

  void _showConsultationDetails(Consulta consultation) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle de consulta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Fecha', consultation.fecha),
            _detailLine('Estado', consultation.estado),
            _detailLine('Motivo', consultation.motivo),
            _detailLine('Notas', consultation.notas),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _payments(BuildContext context, PacienteState state) {
    final payments = state.pagos;
    return _page(context, 'Pagos',
        'Consulta el historial de pagos registrado por tu clínica.', [
      Card(
        child: ListTile(
          leading: const Icon(Icons.card_membership_outlined),
          title: Text(state.suscripcion == null
              ? 'Sin suscripción activa'
              : 'Plan ${state.suscripcion!.plan}'),
          subtitle: Text(state.suscripcion == null
              ? 'La suscripción se habilitará cuando la clínica la configure.'
              : 'Estado: ${state.suscripcion!.estado}'),
          trailing: state.suscripcion == null
              ? FilledButton(
                  onPressed: () => _showSubscriptionOptions(context),
                  child: const Text('Elegir'),
                )
              : null,
        ),
      ),
      const SizedBox(height: 12),
      if (payments.isEmpty) _empty('No hay pagos registrados.'),
      ...payments.map((payment) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(payment.concepto),
              subtitle: Text(
                  '${payment.fecha} · ${payment.estado == PagoEstado.pagado ? 'Pagado' : 'Pendiente'}'),
              trailing: Text('\$${payment.monto.toStringAsFixed(2)}'),
              onTap: () => _showPaymentDetails(payment),
            ),
          )),
    ]);
  }

  Future<void> _showSubscriptionOptions(BuildContext context) async {
    final plan = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Elegir suscripción'),
        children: [
          for (final value in ['BASICO', 'PRO', 'PREMIUM'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Text(value),
            ),
        ],
      ),
    );
    if (plan == null || !mounted) return;
    await ref.read(patientControllerProvider).createSubscription(plan);
  }

  Widget _settings(BuildContext context) {
    return _page(context, 'Configuración', 'Preferencias de tu cuenta.', [
      Card(
        child: ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          subtitle: const Text('Salir de tu cuenta de NNEN'),
          onTap: () => ref.read(authControllerProvider).logout(),
        ),
      ),
    ]);
  }

  Widget _page(BuildContext context, String title, String subtitle,
      List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 22),
        ...children,
      ],
    );
  }

  Widget _metricGrid(List<Widget> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 560
                ? 2
                : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map((item) => SizedBox(width: width, child: item))
                .toList());
      },
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))
                ])),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyCard(String title, List<Widget> fields) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 24, runSpacing: 12, children: fields)
            ])));
  }

  Widget _field(String label, String value) {
    return SizedBox(
        width: 260,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value)
        ]));
  }

  Widget _plansPreview(BuildContext context, List<PlanAlimenticio> plans) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plan actual',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (plans.isEmpty)
                const Text('Tu nutricionista aún no ha asignado un plan.'),
              if (plans.isNotEmpty) _planCard(plans.first)
            ])));
  }

  Widget _reminders(BuildContext context, PacienteState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recordatorios de bienestar',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
                'Activa avisos para mantener tus horarios y hábitos durante el día.'),
            const SizedBox(height: 8),
            if (defaultTargetPlatform != TargetPlatform.android)
              const Text(
                'Las notificaciones del sistema están disponibles actualmente en Android.',
                style: TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 8),
            _reminderTile(
              context,
              id: 100,
              title: 'Recordatorio de agua',
              subtitle: 'Aviso diario para hidratarte',
              icon: Icons.water_drop_outlined,
              defaultTime: const TimeOfDay(hour: 10, minute: 0),
            ),
            _reminderTile(
              context,
              id: 101,
              title: 'Recordatorio de comidas',
              subtitle: 'Aviso diario para revisar tu plan',
              icon: Icons.restaurant_outlined,
              defaultTime: const TimeOfDay(hour: 13, minute: 0),
            ),
            _appointmentReminderTile(context, state),
            const SizedBox(height: 4),
            const Text(
                'Puedes cambiar estos horarios desde el botón de configuración de cada recordatorio.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _reminderTile(
    BuildContext context, {
    required int id,
    required String title,
    required String subtitle,
    required IconData icon,
    required TimeOfDay defaultTime,
  }) {
    final active = _activeReminderIds.contains(id);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(active ? 'Activo' : subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Configurar horario',
            onPressed: () => _configureDailyReminder(
                context, id, title, subtitle, defaultTime),
            icon: const Icon(Icons.schedule_outlined),
          ),
          Switch(
            value: active,
            onChanged: (value) async {
              if (value) {
                await _configureDailyReminder(
                    context, id, title, subtitle, defaultTime);
              } else {
                await _reminderService.cancel(id);
                if (mounted) setState(() => _activeReminderIds.remove(id));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _appointmentReminderTile(BuildContext context, PacienteState state) {
    final next = state.citas
        .map((appointment) => (
              item: appointment,
              date: DateTime.tryParse(appointment.fecha.replaceFirst(' ', 'T'))
            ))
        .where((entry) =>
            entry.date != null && entry.date!.isAfter(DateTime.now()))
        .fold<({CitaPaciente item, DateTime date})?>(null, (current, entry) {
      if (current == null || entry.date!.isBefore(current.date)) {
        return (item: entry.item, date: entry.date!);
      }
      return current;
    });
    final active = _activeReminderIds.contains(102);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: const Text('Recordatorio de cita'),
      subtitle: Text(next == null
          ? 'No tienes citas próximas'
          : active
              ? 'Activo para ${next.item.fecha}'
              : 'Avisar 30 minutos antes de tu próxima cita'),
      trailing: Switch(
        value: active,
        onChanged: next == null
            ? null
            : (value) async {
                if (value) {
                  final granted = await _reminderService.requestPermission();
                  final scheduled = granted &&
                      await _reminderService.scheduleAppointment(
                          id: 102, appointment: next.date);
                  if (mounted && scheduled) {
                    setState(() => _activeReminderIds.add(102));
                    _showReminderMessage('Recordatorio de cita activado');
                  }
                } else {
                  await _reminderService.cancel(102);
                  if (mounted) setState(() => _activeReminderIds.remove(102));
                }
              },
      ),
    );
  }

  Future<void> _configureDailyReminder(
    BuildContext context,
    int id,
    String title,
    String subtitle,
    TimeOfDay defaultTime,
  ) async {
    final time =
        await showTimePicker(context: context, initialTime: defaultTime);
    if (time == null || !mounted) return;
    final granted = await _reminderService.requestPermission();
    if (!granted) {
      _showReminderMessage('Permiso de notificaciones no concedido');
      return;
    }
    final scheduled = await _reminderService.scheduleDaily(
      id: id,
      title: title,
      body: subtitle,
      hour: time.hour,
      minute: time.minute,
    );
    if (mounted && context.mounted && scheduled) {
      setState(() => _activeReminderIds.add(id));
      _showReminderMessage('$title activado a las ${time.format(context)}');
    } else if (mounted && context.mounted) {
      _showReminderMessage(
          'Los recordatorios del sistema están disponibles en Android');
    }
  }

  void _showReminderMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _planCard(PlanAlimenticio plan) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restaurant_menu),
        title: Text(plan.titulo),
        subtitle: Text(
            '${plan.descripcion}\n${plan.fechaInicio} - ${plan.fechaFin}\nObjetivo: ${plan.objetivo}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showPlanDetails(plan),
      ),
    );
  }

  void _showPlanDetails(PlanAlimenticio plan) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(
          plan.titulo,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailLine('Objetivo', plan.objetivo),
                  _detailLine(
                      'Condición',
                      plan.condicion.isEmpty
                          ? 'Sin condición específica'
                          : plan.condicion),
                  _detailLine(
                      'Vigencia', '${plan.fechaInicio} - ${plan.fechaFin}'),
                  _detailLine(
                      'Plantilla',
                      plan.plantillaNombre.isEmpty
                          ? 'Plan personalizado'
                          : plan.plantillaNombre),
                  const SizedBox(height: 12),
                  Text('Indicaciones',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(plan.descripcion),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        textScaler: TextScaler.noScaling,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _progressChart(BuildContext context, List<Evaluacion> evaluations) {
    final ordered = [...evaluations]
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    return Column(
      children: [
        _metricProgressChart(
          context,
          title: 'Evolución del peso',
          unit: 'kg',
          values: ordered.map((item) => item.peso).toList(),
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _metricProgressChart(
          context,
          title: 'Evolución del IMC',
          unit: 'IMC',
          values: ordered.map((item) => item.imc).toList(),
          color: const Color(0xFF356AE6),
        ),
        const SizedBox(height: 12),
        _metricProgressChart(
          context,
          title: 'Evolución de grasa corporal',
          unit: '%',
          values: ordered.map((item) => item.grasa).toList(),
          color: const Color(0xFFE67E22),
        ),
        const SizedBox(height: 12),
        _metricProgressChart(
          context,
          title: 'Evolución de cintura',
          unit: 'cm',
          values: ordered.map((item) => item.cintura).toList(),
          color: const Color(0xFF8E44AD),
        ),
        const SizedBox(height: 12),
        _metricProgressChart(
          context,
          title: 'Evolución de cadera',
          unit: 'cm',
          values: ordered.map((item) => item.cadera).toList(),
          color: const Color(0xFF16A085),
        ),
        const SizedBox(height: 12),
        _metricProgressChart(
          context,
          title: 'Evolución del músculo',
          unit: '%',
          values: ordered.map((item) => item.porcentajeMusculo).toList(),
          color: const Color(0xFF2C3E50),
        ),
        const SizedBox(height: 12),
        _comparisonCard(context, ordered),
      ],
    );
  }

  Widget _metricProgressChart(
    BuildContext context, {
    required String title,
    required String unit,
    required List<double> values,
    required Color color,
  }) {
    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final padding = (maximum - minimum).abs() < 0.01
        ? (maximum.abs() * 0.08).clamp(1.0, double.infinity)
        : (maximum - minimum) * 0.15;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Valores expresados en $unit',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (values.length - 1).toDouble(),
                  minY: (minimum - padding).clamp(0, double.infinity),
                  maxY: maximum + padding,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: _chartLabel)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      spots: [
                        for (var i = 0; i < values.length; i++)
                          FlSpot(i.toDouble(), values[i]),
                      ],
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chartLabel(double value, TitleMeta meta) {
    return Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10));
  }

  Widget _comparisonCard(BuildContext context, List<Evaluacion> evaluations) {
    final latest = evaluations.last;
    final previous =
        evaluations.length > 1 ? evaluations[evaluations.length - 2] : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparación de progreso',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(previous == null
                ? 'Esta es tu primera evaluación registrada.'
                : 'Comparación entre la última y la evaluación anterior.'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _progressStat('Peso', latest.peso, previous?.peso, 'kg'),
                _progressStat('Altura', latest.altura, previous?.altura, 'm'),
                _progressStat('Grasa', latest.grasa, previous?.grasa, '%'),
                _progressStat('IMC', latest.imc, previous?.imc, ''),
                _progressStat(
                    'Cintura', latest.cintura, previous?.cintura, 'cm'),
                _progressStat('Cadera', latest.cadera, previous?.cadera, 'cm'),
                _progressStat('Músculo', latest.porcentajeMusculo,
                    previous?.porcentajeMusculo, '%'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Última actualización: ${latest.fecha}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressStat(
      String label, double current, double? previous, String unit) {
    final difference = previous == null ? null : current - previous;
    final differenceText = difference == null
        ? 'Sin comparación'
        : '${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(1)} $unit';
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${current.toStringAsFixed(1)} $unit'.trim(),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(differenceText, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _evaluationTile(Evaluacion evaluation) => Card(
      child: ListTile(
          leading: const Icon(Icons.monitor_weight_outlined),
          title: Text(
              '${evaluation.fecha} · ${evaluation.peso.toStringAsFixed(1)} kg'),
          subtitle: Text('Altura ${evaluation.altura.toStringAsFixed(2)} m · '
              'IMC ${evaluation.imc.toStringAsFixed(1)} · '
              'Grasa ${evaluation.grasa.toStringAsFixed(1)} %')));

  Widget _empty(String text) => Card(
      child: Padding(padding: const EdgeInsets.all(22), child: Text(text)));

  Widget _messageBanner(String text, bool error) => Card(
      color: error ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(padding: const EdgeInsets.all(12), child: Text(text)));

  Widget _invitationsCard(BuildContext context, PacienteState state,
      PacienteController controller) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invitaciones pendientes',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Un nutricionista quiere vincularte como paciente.'),
            const SizedBox(height: 8),
            ...state.invitations.map((invitation) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                      child: Icon(Icons.person_add_alt_1_outlined)),
                  title: Text(invitation.nutricionistaNombre),
                  subtitle: Text(invitation.nutricionistaCorreo),
                  trailing: OverflowBar(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Rechazar',
                        onPressed: () =>
                            controller.rejectInvitation(invitation.id),
                        icon: const Icon(Icons.close),
                      ),
                      FilledButton(
                        onPressed: () =>
                            controller.acceptInvitation(invitation.id),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  bool _isPast(String value) {
    final date = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    return date != null && date.isBefore(DateTime.now());
  }

  void _showAppointmentDetails(CitaPaciente appointment) {
    final date = DateTime.tryParse(appointment.fecha.replaceFirst(' ', 'T'));
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalle de la cita'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailLine('Fecha y hora', appointment.fecha),
              _detailLine('Motivo', appointment.motivo),
              _detailLine('Estado', _appointmentLabel(appointment.estado)),
              _detailLine('Recordatorio', appointment.canalRecordatorio),
              if (date != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  width: 320,
                  child: CalendarDatePicker(
                    initialDate: date,
                    firstDate: DateTime(date.year - 2),
                    lastDate: DateTime(date.year + 2),
                    onDateChanged: (_) {},
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showEvaluationDetails(Evaluacion evaluation) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalle de evaluación'),
        content: Text(
          'Fecha: ${evaluation.fecha}\nPeso: ${evaluation.peso.toStringAsFixed(1)} kg\n'
          'Altura: ${evaluation.altura.toStringAsFixed(2)} m\n'
          'Grasa corporal: ${evaluation.grasa.toStringAsFixed(1)} %\n'
          'IMC: ${evaluation.imc.toStringAsFixed(1)}\n'
          'TMB: ${evaluation.tmb.toStringAsFixed(0)} kcal\n'
          'GET: ${evaluation.get.toStringAsFixed(0)} kcal',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showPaymentDetails(PagoPaciente payment) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalle del pago'),
        content: Text(
          'Concepto: ${payment.concepto}\nMonto: \$${payment.monto.toStringAsFixed(2)}\n'
          'Fecha: ${payment.fecha}\nEstado: ${payment.estado == PagoEstado.pagado ? 'Pagado' : 'Pendiente'}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _errorView(String message, PacienteController controller) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: controller.load, child: const Text('Reintentar'))
          ])));

  _Metrics _metrics(Paciente patient) {
    final imc = patient.altura > 0
        ? patient.peso / (patient.altura * patient.altura)
        : 0.0;
    final heightCm = patient.altura * 100;
    final adjustment =
        patient.sexo.toLowerCase().contains('masc') ? 5.0 : -161.0;
    final tmb = ((10 * patient.peso) +
            (6.25 * heightCm) -
            (5 * patient.edad) +
            adjustment)
        .toDouble();
    return _Metrics(imc, tmb, tmb * patient.factorActividad);
  }

  String _imcLabel(double imc) => imc < 18.5
      ? 'Bajo peso'
      : imc < 25
          ? 'Normal'
          : imc < 30
              ? 'Sobrepeso'
              : 'Obesidad';

  String _appointmentLabel(CitaEstado status) => switch (status) {
        CitaEstado.agendada => 'Agendada',
        CitaEstado.reprogramada => 'Reprogramada',
        CitaEstado.completada => 'Completada',
        CitaEstado.cancelada => 'Cancelada'
      };

  Future<void> _openWhatsapp(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(
        Uri.parse('https://wa.me/${normalized.replaceFirst('+', '')}'));
  }
}

class _Metrics {
  const _Metrics(this.imc, this.tmb, this.get);
  final double imc;
  final double tmb;
  final double get;
}

class PatientChatScreen extends ConsumerStatefulWidget {
  const PatientChatScreen({super.key, required this.profile});

  final PacienteProfile profile;

  @override
  ConsumerState<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends ConsumerState<PatientChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(patientControllerProvider);
    final messages = controller.state.mensajes;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(widget.profile.nutricionistaNombre.isEmpty
                  ? '?'
                  : widget.profile.nutricionistaNombre
                      .substring(0, 1)
                      .toUpperCase()),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.profile.nutricionistaNombre,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          if (widget.profile.nutricionistaWhatsapp.isNotEmpty)
            IconButton(
              tooltip: 'Abrir WhatsApp',
              icon: const Icon(Icons.phone),
              onPressed: () =>
                  _openWhatsapp(widget.profile.nutricionistaWhatsapp),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Aún no hay mensajes.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _messageBubble(context, messages[index], 'paciente'),
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

  Widget _composer(BuildContext context, PacienteController controller) {
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
              onPressed: controller.state.isSending
                  ? null
                  : () async {
                      final content = _messageController.text.trim();
                      if (content.isEmpty) return;
                      await controller.sendMessage(content);
                      _messageController.clear();
                    },
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsapp(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(
        Uri.parse('https://wa.me/${normalized.replaceFirst('+', '')}'));
  }
}
