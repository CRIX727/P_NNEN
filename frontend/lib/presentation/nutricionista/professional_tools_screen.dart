import 'package:flutter/material.dart';

import '../../core/nutrition/nutrition_calculator.dart';
import '../../domain/entities/alimento.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../core/services/clinical_report_service.dart';
import 'nutricionista_controller.dart';
import 'nutricionista_state.dart';

class ProfessionalToolsScreen extends StatefulWidget {
  const ProfessionalToolsScreen({
    super.key,
    required this.state,
    required this.controller,
  });

  final NutricionistaState state;
  final NutricionistaController controller;

  @override
  State<ProfessionalToolsScreen> createState() =>
      _ProfessionalToolsScreenState();
}

class _ProfessionalToolsScreenState extends State<ProfessionalToolsScreen> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController(text: '30');
  final _sex = TextEditingController(text: 'Femenino');
  final _activity = TextEditingController(text: '1.2');
  final _targetCalories = TextEditingController();
  final _protein = TextEditingController(text: '25');
  final _carbs = TextEditingController(text: '50');
  final _fat = TextEditingController(text: '25');
  final _waist = TextEditingController();
  final _hip = TextEditingController();
  final _arm = TextEditingController();
  final _skinfold = TextEditingController();
  final _foodSearch = TextEditingController();
  final _planTitle = TextEditingController(text: 'Plan profesional');
  final _planDescription = TextEditingController();
  final _planMeals = TextEditingController();
  final _planShopping = TextEditingController();
  final _planSubstitutions = TextEditingController();
  EnergyFormula _formula = EnergyFormula.mifflin;
  String _period = 'Diario';
  String _foodCondition = 'Todos';
  EnergyResult? _energy;

  @override
  void dispose() {
    for (final c in [
      _weight,
      _height,
      _age,
      _sex,
      _activity,
      _targetCalories,
      _protein,
      _carbs,
      _fat,
      _waist,
      _hip,
      _arm,
      _skinfold,
      _foodSearch,
      _planTitle,
      _planDescription,
      _planMeals,
      _planShopping,
      _planSubstitutions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.state.selectedPatient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Herramientas profesionales',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
            'Cálculos, dietocálculo, alimentos y planes en un solo lugar.'),
        const SizedBox(height: 16),
        _energyCard(context, patient),
        _dietCard(context),
        _anthropometryCard(context, patient),
        _foodCard(context),
        _planBuilder(context, patient),
        if (patient != null) _reportCard(context, patient),
      ],
    );
  }

  Widget _energyCard(BuildContext context, Paciente? patient) {
    return _section(
      context,
      icon: Icons.calculate_outlined,
      title: 'Calculadora nutricional',
      child: Column(
        children: [
          _responsiveFields([
            _input(_weight, 'Peso (kg)', initial: patient?.peso),
            _input(_height, 'Altura (m)', initial: patient?.altura),
            _input(_age, 'Edad', integer: true, initial: patient?.edad),
            _input(_sex, 'Sexo'),
            _input(_activity, 'Factor de actividad'),
          ]),
          DropdownButtonFormField<EnergyFormula>(
            initialValue: _formula,
            decoration: const InputDecoration(labelText: 'Fórmula energética'),
            items: EnergyFormula.values
                .map((formula) => DropdownMenuItem(
                    value: formula, child: Text(formula.label)))
                .toList(),
            onChanged: (value) => setState(() => _formula = value ?? _formula),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _calculateEnergy,
            icon: const Icon(Icons.auto_graph),
            label: const Text('Calcular requerimientos'),
          ),
          if (_energy != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _result(
                  context, 'TMB', '${_energy!.tmb.toStringAsFixed(0)} kcal'),
              _result(
                  context, 'ETA', '${_energy!.eta.toStringAsFixed(0)} kcal'),
              _result(
                  context, 'GET', '${_energy!.get.toStringAsFixed(0)} kcal'),
              _result(context, 'Agua',
                  '${_energy!.waterLiters.toStringAsFixed(1)} L'),
              _result(context, 'Peso saludable',
                  '${_energy!.healthyMin.toStringAsFixed(1)} - ${_energy!.healthyMax.toStringAsFixed(1)} kg'),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _dietCard(BuildContext context) {
    final percentages = NutritionCalculator.macroPercentages(
      protein: _number(_protein),
      carbohydrates: _number(_carbs),
      fat: _number(_fat),
    );
    return _section(
      context,
      icon: Icons.restaurant_outlined,
      title: 'Dietocálculo y recordatorio de 24 horas',
      child: Column(children: [
        _responsiveFields([
          _input(_targetCalories, 'Calorías objetivo'),
          _input(_protein, 'Proteínas (g)'),
          _input(_carbs, 'Carbohidratos (g)'),
          _input(_fat, 'Grasas (g)'),
        ]),
        _responsiveFields([
          _multiline('Desayuno', maxLines: 2),
          _multiline('Almuerzo', maxLines: 2),
          _multiline('Cena', maxLines: 2),
          _multiline('Meriendas', maxLines: 2),
        ]),
        Wrap(
            spacing: 8,
            children: percentages.entries
                .map((item) => Chip(
                    label:
                        Text('${item.key}: ${item.value.toStringAsFixed(0)}%')))
                .toList()),
        const SizedBox(height: 8),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Conversión rápida de porciones: gramos, unidades, tazas y cucharadas se pueden convertir antes de agregarlas al plan.')),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Distribución sugerida: desayuno 25%, almuerzo 35%, cena 25%, meriendas 15%')),
      ]),
    );
  }

  Widget _anthropometryCard(BuildContext context, Paciente? patient) {
    final weight =
        _number(_weight) == 0 ? patient?.peso ?? 0 : _number(_weight);
    final height =
        _number(_height) == 0 ? patient?.altura ?? 0 : _number(_height);
    final waist =
        _number(_waist) == 0 ? patient?.cintura ?? 0 : _number(_waist);
    final hip = _number(_hip) == 0 ? patient?.cadera ?? 0 : _number(_hip);
    final arm = _number(_arm) == 0 ? patient?.brazo ?? 0 : _number(_arm);
    return _section(
      context,
      icon: Icons.monitor_weight_outlined,
      title: 'Evaluación antropométrica avanzada',
      child: Column(children: [
        _responsiveFields([
          _input(_waist, 'Cintura (cm)'),
          _input(_hip, 'Cadera (cm)'),
          _input(_arm, 'Brazo (cm)'),
          _input(_skinfold, 'Pliegue tricipital (mm)'),
        ]),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _result(context, 'IMC',
              NutritionCalculator.bmi(weight, height).toStringAsFixed(1)),
          _result(context, 'Cintura/cadera',
              NutritionCalculator.waistHipRatio(waist, hip).toStringAsFixed(2)),
          _result(context, 'Área muscular brazo',
              '${NutritionCalculator.armMuscleArea(arm, _number(_skinfold)).toStringAsFixed(1)} cm²'),
        ]),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text(
                'Los valores se comparan con el historial de evaluaciones del paciente en su ficha clínica.')),
      ]),
    );
  }

  Widget _foodCard(BuildContext context) {
    final search = _foodSearch.text.toLowerCase();
    final foods = widget.state.foods
        .where((food) => food.nombre.toLowerCase().contains(search))
        .toList();
    return _section(
      context,
      icon: Icons.food_bank_outlined,
      title: 'Base profesional de alimentos',
      child: Column(children: [
        TextField(
            controller: _foodSearch,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
                labelText: 'Buscar alimento', prefixIcon: Icon(Icons.search))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _foodCondition,
          decoration: const InputDecoration(labelText: 'Condición'),
          items: const ['Todos', 'Diabetes', 'Renal', 'Hipertensión']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) =>
              setState(() => _foodCondition = value ?? 'Todos'),
        ),
        const SizedBox(height: 8),
        if (foods.isEmpty)
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('No hay alimentos registrados todavía.'))
        else
          ...foods.take(12).map((food) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant),
                title: Text(food.nombre),
                subtitle: Text(
                    '${food.porcion} · ${food.calorias.toStringAsFixed(0)} kcal · P ${food.proteinas.toStringAsFixed(1)} g · C ${food.carbohidratos.toStringAsFixed(1)} g · G ${food.grasas.toStringAsFixed(1)} g'),
                onTap: () => _addFoodToPlan(food),
              )),
      ]),
    );
  }

  Widget _planBuilder(BuildContext context, Paciente? patient) {
    return _section(
      context,
      icon: Icons.menu_book_outlined,
      title: 'Constructor de planes profesionales',
      child: Column(children: [
        _responsiveFields([
          _input(_planTitle, 'Nombre del plan'),
          DropdownButtonFormField<String>(
              initialValue: _period,
              decoration: const InputDecoration(labelText: 'Periodo'),
              items: const ['Diario', 'Semanal', 'Mensual']
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => _period = value ?? _period)),
        ]),
        _multiline('Descripción y objetivo',
            maxLines: 3, controller: _planDescription),
        _multiline('Comidas, porciones y recetas',
            maxLines: 5, controller: _planMeals),
        _multiline('Sustituciones y lista de compras',
            maxLines: 4, controller: _planSubstitutions),
        _multiline('Lista de compras detallada',
            maxLines: 3, controller: _planShopping),
        Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
                onPressed: patient == null ? null : () => _savePlan(patient),
                icon: const Icon(Icons.save),
                label: const Text('Guardar plan para paciente'))),
      ]),
    );
  }

  Widget _reportCard(BuildContext context, Paciente patient) => _section(
        context,
        icon: Icons.picture_as_pdf_outlined,
        title: 'Reportes clínicos',
        child: Row(children: [
          const Expanded(
              child: Text(
                  'Genera una ficha con datos clínicos, medidas, evaluaciones y planes del paciente seleccionado.')),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => ClinicalReportService().printPatientReport(
              patient: patient,
              evaluations: widget.state.evaluations,
              plans: widget.state.plans,
            ),
            icon: const Icon(Icons.download),
            label: const Text('Exportar PDF'),
          ),
        ]),
      );

  Widget _section(BuildContext context,
          {required IconData icon,
          required String title,
          required Widget child}) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge))
              ]),
              const SizedBox(height: 14),
              child,
            ])),
      );

  Widget _input(TextEditingController controller, String label,
      {bool integer = false, num? initial}) {
    if (controller.text.isEmpty && initial != null) {
      controller.text =
          integer ? initial.toInt().toString() : initial.toString();
    }
    return TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !integer),
        decoration: InputDecoration(labelText: label));
  }

  Widget _multiline(String label,
          {int maxLines = 2, TextEditingController? controller}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(labelText: label)));

  Widget _responsiveFields(List<Widget> fields) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth < 700
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;
        return Wrap(
            spacing: 16,
            runSpacing: 4,
            children: fields
                .map((field) => SizedBox(
                    width: width,
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: field)))
                .toList());
      });

  Widget _result(BuildContext context, String label, String value) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium)
      ]));

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  void _calculateEnergy() {
    final result = NutritionCalculator.calculate(EnergyInput(
        weightKg: _number(_weight),
        heightCm: _number(_height) * 100,
        age: int.tryParse(_age.text) ?? 30,
        sex: _sex.text,
        activityFactor: _number(_activity) == 0 ? 1.2 : _number(_activity),
        formula: _formula));
    setState(() => _energy = result);
  }

  void _addFoodToPlan(Alimento food) {
    _planMeals.text = _planMeals.text.isEmpty
        ? '${food.nombre} (${food.porcion})'
        : '${_planMeals.text}\n${food.nombre} (${food.porcion})';
    final calories = _number(_targetCalories) + food.calorias;
    _targetCalories.text = calories.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _savePlan(Paciente patient) async {
    await widget.controller.addPlan(
        patient.id,
        PlanAlimenticio(
            id: 0,
            pacienteId: patient.id,
            titulo: _planTitle.text.trim().isEmpty
                ? 'Plan profesional'
                : _planTitle.text.trim(),
            descripcion: _planDescription.text.trim(),
            objetivo: _period,
            condicion: patient.enfermedades,
            plantillaNombre: '',
            fechaInicio: _today(),
            fechaFin: _today(),
            comidas: _planMeals.text.trim(),
            sustituciones:
                '${_planSubstitutions.text.trim()}\nLista de compras: ${_planShopping.text.trim()}',
            calorias: _number(_targetCalories),
            proteinas: _number(_protein),
            carbohidratos: _number(_carbs),
            grasasMacros: _number(_fat),
            periodo: _period,
            listaCompras: _planShopping.text.trim(),
            recetas: _planMeals.text.trim(),
            distribucionCalorias:
                'Desayuno 25% · Almuerzo 35% · Cena 25% · Meriendas 15%',
            aguaRecomendada: _energy?.waterLiters ?? 0));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan profesional guardado')));
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
