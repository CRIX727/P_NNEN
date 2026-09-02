import 'package:flutter/foundation.dart';

import '../../data/repositories/nutritionist_repository.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/plantilla_plan.dart';
import 'nutricionista_state.dart';

class NutricionistaController extends ChangeNotifier {
  NutricionistaController(this._repository);

  final NutritionistRepository _repository;

  NutricionistaState _state = const NutricionistaState.initial();
  NutricionistaState get state => _state;

  Future<void> loadAll() async {
    _emit(_state.copyWith(loading: true, clearMessage: true));
    try {
      final summary = await _repository.getDashboard();
      final pacientes = await _repository.getPatients();
      final templates = await _repository.getTemplates();
      final settings = await _repository.getSettings();
      _emit(
        _state.copyWith(
          loading: false,
          summary: summary,
          pacientes: pacientes,
          templates: templates,
          settings: settings,
          selectedPatient: pacientes.isNotEmpty ? pacientes.first : null,
        ),
      );
      if (pacientes.isNotEmpty) {
        await selectPatient(pacientes.first.id);
      }
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  void setSection(NutricionistaSection section) {
    _emit(_state.copyWith(section: section, clearMessage: true));
  }

  Future<void> selectPatient(int id) async {
    try {
      final patient = await _repository.getPatient(id);
      final evaluations = await _repository.getEvaluations(id);
      final plans = await _repository.getPlans(id);
      final appointments = await _repository.getAppointments(id);
      final messages = await _repository.getMessages(id);
      final payments = await _repository.getPayments(id);
      final documents = await _repository.getDocuments(id);

      _emit(
        _state.copyWith(
          selectedPatient: patient,
          evaluations: evaluations,
          plans: plans,
          appointments: appointments,
          messages: messages,
          payments: payments,
          documents: documents,
        ),
      );
    } catch (error) {
      _emit(_state.copyWith(message: _message(error)));
    }
  }

  Future<void> createPatient(Paciente patient) async {
    _setBusy(true);
    try {
      await _repository.createPatient(patient);
      await loadAll();
      _emit(_state.copyWith(message: 'Paciente agregado correctamente'));
      setSection(NutricionistaSection.misPacientes);
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> updatePatient(Paciente patient) async {
    _setBusy(true);
    try {
      await _repository.updatePatient(patient);
      await loadAll();
      if (_state.selectedPatient != null) {
        await selectPatient(patient.id);
      }
      _emit(_state.copyWith(message: 'Paciente actualizado'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addEvaluation(
    int patientId,
    double peso,
    double altura,
    double grasa,
    String fecha,
  ) async {
    _setBusy(true);
    try {
      await _repository.createEvaluation(patientId, peso, altura, grasa, fecha);
      await selectPatient(patientId);
      await loadAll();
      _emit(_state.copyWith(message: 'Evaluación registrada'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addPlan(int patientId, PlanAlimenticio plan) async {
    _setBusy(true);
    try {
      await _repository.createPlan(patientId, plan);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Plan alimenticio guardado'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addAppointment(int patientId, CitaPaciente appointment) async {
    _setBusy(true);
    try {
      await _repository.createAppointment(patientId, appointment);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Cita guardada'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addMessage(int patientId, MensajePaciente message) async {
    _setBusy(true);
    try {
      await _repository.createMessage(patientId, message);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Mensaje enviado'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addPayment(int patientId, PagoPaciente payment) async {
    _setBusy(true);
    try {
      await _repository.createPayment(patientId, payment);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Pago registrado'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addDocument(int patientId, DocumentoPaciente document) async {
    _setBusy(true);
    try {
      await _repository.createDocument(patientId, document);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Documento adjuntado'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> saveTemplate(PlantillaPlan template) async {
    _setBusy(true);
    try {
      await _repository.createTemplate(template);
      await loadAll();
      _emit(_state.copyWith(message: 'Plantilla guardada'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> saveSettings(NutricionistaSettings settings) async {
    _setBusy(true);
    try {
      final updated = await _repository.updateSettings(settings);
      _emit(
        _state.copyWith(
          loading: false,
          settings: updated,
          message: 'Configuración guardada',
        ),
      );
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  void _setBusy(bool busy) {
    _emit(_state.copyWith(loading: busy, clearMessage: true));
  }

  void _emit(NutricionistaState newState) {
    _state = newState;
    notifyListeners();
  }

  String _message(Object error) {
    final text = error.toString();
    if (text.contains('Exception:')) {
      return text.replaceFirst('Exception:', '').trim();
    }
    return text;
  }
}
