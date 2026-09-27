import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/pago_paciente.dart';
import 'paciente_controller.dart';
import 'paciente_state.dart';

class PacientePanelScreen extends ConsumerStatefulWidget {
  const PacientePanelScreen({super.key});

  @override
  ConsumerState<PacientePanelScreen> createState() => _PacientePanelScreenState();
}

class _PacientePanelScreenState extends ConsumerState<PacientePanelScreen> {
  final _messageController = TextEditingController();

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
                  Text('NNEN', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 4)),
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
                  _menuItem(context, controller, PacienteSection.resumen, Icons.home_outlined, 'Resumen'),
                  _menuItem(context, controller, PacienteSection.perfil, Icons.person_outline, 'Mi perfil'),
                  _menuItem(context, controller, PacienteSection.planes, Icons.restaurant_menu, 'Mi plan alimenticio'),
                  _menuItem(context, controller, PacienteSection.progreso, Icons.show_chart, 'Mi progreso'),
                  _menuItem(context, controller, PacienteSection.citas, Icons.calendar_month_outlined, 'Citas y recordatorios'),
                  _menuItem(context, controller, PacienteSection.comunicacion, Icons.chat_bubble_outline, 'Comunicación'),
                  _menuItem(context, controller, PacienteSection.historial, Icons.history, 'Historial de consultas'),
                  _menuItem(context, controller, PacienteSection.pagos, Icons.receipt_long_outlined, 'Pagos'),
                  _menuItem(context, controller, PacienteSection.configuracion, Icons.settings_outlined, 'Configuración'),
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

  Widget _buildContent(BuildContext context, PacienteState state, PacienteController controller) {
    final content = switch (state.section) {
      PacienteSection.resumen => _summary(context, state),
      PacienteSection.perfil => _profile(context, state),
      PacienteSection.planes => _plans(context, state.planes),
      PacienteSection.progreso => _progress(context, state),
      PacienteSection.citas => _appointments(context, state.citas),
      PacienteSection.comunicacion => _communication(context, state, controller),
      PacienteSection.historial => _history(context, state),
      PacienteSection.pagos => _payments(context, state.pagos),
      PacienteSection.configuracion => _settings(context),
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (state.error != null) _messageBanner(state.error!, true),
          if (state.message != null) _messageBanner(state.message!, false),
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
          _metric('IMC actual', metrics.imc.toStringAsFixed(1), Icons.monitor_weight_outlined),
          _metric('TMB', '${metrics.tmb.toStringAsFixed(0)} kcal', Icons.local_fire_department_outlined),
          _metric('GET', '${metrics.get.toStringAsFixed(0)} kcal', Icons.bolt_outlined),
          _metric('Grasa corporal', '${patient.grasaCorporal.toStringAsFixed(1)} %', Icons.pie_chart_outline),
        ]),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(next == null ? 'Sin citas próximas' : 'Próxima cita: ${next.fecha}'),
            subtitle: Text(next == null ? 'Cuando tu nutricionista agende una cita aparecerá aquí.' : next.motivo),
          ),
        ),
        const SizedBox(height: 18),
        _reminders(context),
        const SizedBox(height: 18),
        _plansPreview(context, state.planes),
      ],
    );
  }

  Widget _profile(BuildContext context, PacienteState state) {
    final patient = state.profile!.paciente;
    final metrics = _metrics(patient);
    return _page(context, 'Mi perfil', 'Estos datos fueron registrados por tu nutricionista.', [
      _readOnlyCard('Datos personales', [
        _field('Nombre', patient.nombre),
        _field('Correo', patient.correo),
        _field('Edad', '${patient.edad} años'),
        _field('Sexo', patient.sexo),
        _field('Teléfono', patient.telefono.isEmpty ? 'No registrado' : patient.telefono),
      ]),
      const SizedBox(height: 16),
      _readOnlyCard('Datos nutricionales', [
        _field('Peso', '${patient.peso.toStringAsFixed(1)} kg'),
        _field('Altura', '${patient.altura.toStringAsFixed(2)} m'),
        _field('Grasa corporal', '${patient.grasaCorporal.toStringAsFixed(1)} %'),
        _field('IMC', '${metrics.imc.toStringAsFixed(1)} · ${_imcLabel(metrics.imc)}'),
        _field('TMB', '${metrics.tmb.toStringAsFixed(0)} kcal/día'),
        _field('GET', '${metrics.get.toStringAsFixed(0)} kcal/día'),
        _field('Alergias', patient.alergias.isEmpty ? 'No registradas' : patient.alergias),
        _field('Enfermedades', patient.enfermedades.isEmpty ? 'No registradas' : patient.enfermedades),
      ]),
      const SizedBox(height: 16),
      _readOnlyCard('Mi nutricionista', [
        _field('Nombre', state.profile!.nutricionistaNombre),
        _field('Correo', state.profile!.nutricionistaCorreo),
      ]),
    ]);
  }

  Widget _plans(BuildContext context, List<PlanAlimenticio> plans) {
    return _page(context, 'Mi plan alimenticio', 'Consulta las indicaciones compartidas contigo.', [
      if (plans.isEmpty) _empty('Aún no tienes planes alimenticios asignados.'),
      ...plans.map(_planCard),
    ]);
  }

  Widget _progress(BuildContext context, PacienteState state) {
    final evaluations = state.evaluaciones;
    return _page(context, 'Mi progreso', 'Compara tus evaluaciones a lo largo del tiempo.', [
      if (evaluations.isEmpty) _empty('Aún no hay evaluaciones para mostrar.'),
      if (evaluations.isNotEmpty) _progressChart(context, evaluations),
      const SizedBox(height: 16),
      ...evaluations.reversed.map((item) => _evaluationTile(item)),
    ]);
  }

  Widget _appointments(BuildContext context, List<CitaPaciente> appointments) {
    return _page(context, 'Citas y recordatorios', 'Aquí aparecerán tus consultas programadas.', [
      if (appointments.isEmpty) _empty('No tienes citas registradas.'),
      ...appointments.map((appointment) => Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(appointment.fecha),
              subtitle: Text('${appointment.motivo}\nRecordatorio: ${appointment.canalRecordatorio}'),
              isThreeLine: true,
              trailing: Chip(label: Text(_appointmentLabel(appointment.estado))),
            ),
          )),
    ]);
  }

  Widget _communication(BuildContext context, PacienteState state, PacienteController controller) {
    final profile = state.profile!;
    return _page(context, 'Comunicación', 'Escribe a tu nutricionista desde NNEN.', [
      Card(
        child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(profile.nutricionistaNombre),
          subtitle: Text(profile.nutricionistaCorreo),
          trailing: profile.nutricionistaWhatsapp.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Abrir WhatsApp',
                  icon: const Icon(Icons.phone),
                  onPressed: () => _openWhatsapp(profile.nutricionistaWhatsapp),
                ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (state.mensajes.isEmpty) const Text('Todavía no hay mensajes.'),
              ...state.mensajes.map((message) => Align(
                    alignment: message.remitente == 'paciente'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 620),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.remitente == 'paciente'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(message.contenido),
                    ),
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Escribe un mensaje',
                  suffixIcon: IconButton(
                    onPressed: state.isSending
                        ? null
                        : () async {
                            await controller.sendMessage(_messageController.text);
                            _messageController.clear();
                          },
                    icon: const Icon(Icons.send),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _history(BuildContext context, PacienteState state) {
    return _page(context, 'Historial de consultas', 'Consulta tus evaluaciones anteriores.', [
      if (state.evaluaciones.isEmpty) _empty('No hay consultas registradas.'),
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
            ),
          )),
    ]);
  }

  Widget _payments(BuildContext context, List<PagoPaciente> payments) {
    return _page(context, 'Pagos', 'Consulta el historial de pagos registrado por tu clínica.', [
      if (payments.isEmpty) _empty('No hay pagos registrados.'),
      ...payments.map((payment) => Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(payment.concepto),
              subtitle: Text('${payment.fecha} · ${payment.estado == PagoEstado.pagado ? 'Pagado' : 'Pendiente'}'),
              trailing: Text('\$${payment.monto.toStringAsFixed(2)}'),
            ),
          )),
    ]);
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

  Widget _page(BuildContext context, String title, String subtitle, List<Widget> children) {
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
        final columns = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 560 ? 2 : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: metrics.map((item) => SizedBox(width: width, child: item)).toList());
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))])),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyCard(String title, List<Widget> fields) {
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Wrap(spacing: 24, runSpacing: 12, children: fields)])));
  }

  Widget _field(String label, String value) {
    return SizedBox(width: 260, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(value)]));
  }

  Widget _plansPreview(BuildContext context, List<PlanAlimenticio> plans) {
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Plan actual', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 10), if (plans.isEmpty) const Text('Tu nutricionista aún no ha asignado un plan.'), if (plans.isNotEmpty) _planCard(plans.first)])));
  }

  Widget _reminders(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recordatorios de bienestar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.water_drop_outlined),
              title: Text('Toma agua durante el día'),
              subtitle: Text('Mantén una hidratación constante.'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.restaurant_outlined),
              title: Text('Revisa tus comidas'),
              subtitle: Text('Consulta tu plan en los horarios indicados.'),
            ),
            const Text('Estos recordatorios son informativos. Las notificaciones del dispositivo se habilitarán en la siguiente etapa de notificaciones.', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _planCard(PlanAlimenticio plan) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restaurant_menu),
        title: Text(plan.titulo),
        subtitle: Text('${plan.descripcion}\n${plan.fechaInicio} - ${plan.fechaFin}\nObjetivo: ${plan.objetivo}'),
        isThreeLine: true,
      ),
    );
  }

  Widget _progressChart(BuildContext context, List<Evaluacion> evaluations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 22, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Evolución del peso', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 22),
          SizedBox(
            height: 240,
            child: LineChart(LineChartData(
              minX: 0,
              maxX: (evaluations.length - 1).toDouble(),
              minY: evaluations.map((e) => e.peso).reduce((a, b) => a < b ? a : b) - 2,
              maxY: evaluations.map((e) => e.peso).reduce((a, b) => a > b ? a : b) + 2,
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
              borderData: FlBorderData(show: false),
              lineBarsData: [LineChartBarData(isCurved: true, spots: [for (var i = 0; i < evaluations.length; i++) FlSpot(i.toDouble(), evaluations[i].peso)], dotData: const FlDotData(show: true))],
            )),
          ),
        ]),
      ),
    );
  }

  Widget _evaluationTile(Evaluacion evaluation) => Card(child: ListTile(leading: const Icon(Icons.monitor_weight_outlined), title: Text('${evaluation.fecha} · ${evaluation.peso.toStringAsFixed(1)} kg'), subtitle: Text('IMC ${evaluation.imc.toStringAsFixed(1)} · Grasa ${evaluation.grasa.toStringAsFixed(1)} %')));

  Widget _empty(String text) => Card(child: Padding(padding: const EdgeInsets.all(22), child: Text(text)));

  Widget _messageBanner(String text, bool error) => Card(color: error ? Colors.red.shade50 : Colors.green.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(text)));

  Widget _errorView(String message, PacienteController controller) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: controller.load, child: const Text('Reintentar'))])));

  _Metrics _metrics(Paciente patient) {
    final imc = patient.altura > 0 ? patient.peso / (patient.altura * patient.altura) : 0.0;
    final heightCm = patient.altura * 100;
    final adjustment = patient.sexo.toLowerCase().contains('masc') ? 5.0 : -161.0;
    final tmb = ((10 * patient.peso) + (6.25 * heightCm) - (5 * patient.edad) + adjustment).toDouble();
    return _Metrics(imc, tmb, tmb * patient.factorActividad);
  }

  String _imcLabel(double imc) => imc < 18.5 ? 'Bajo peso' : imc < 25 ? 'Normal' : imc < 30 ? 'Sobrepeso' : 'Obesidad';

  String _appointmentLabel(CitaEstado status) => switch (status) { CitaEstado.agendada => 'Agendada', CitaEstado.reprogramada => 'Reprogramada', CitaEstado.completada => 'Completada', CitaEstado.cancelada => 'Cancelada' };

  Future<void> _openWhatsapp(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('https://wa.me/${normalized.replaceFirst('+', '')}'));
  }
}

class _Metrics {
  const _Metrics(this.imc, this.tmb, this.get);
  final double imc;
  final double tmb;
  final double get;
}
