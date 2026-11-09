import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/session_manager.dart';
import '../../data/remote/chat_socket_service.dart';
import '../../data/repositories/nutritionist_repository.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/consulta.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/nutricionista_settings.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import '../../domain/entities/tarea_nutricionista.dart';
import '../../domain/entities/plantilla_plan.dart';
import 'nutricionista_state.dart';

class NutricionistaController extends ChangeNotifier {
  NutricionistaController(this._repository, this._chat, this._sessionManager);

  final NutritionistRepository _repository;
  final ChatSocketService _chat;
  final SessionManager _sessionManager;
  StreamSubscription? _messageSubscription;

  NutricionistaState _state = const NutricionistaState.initial();
  NutricionistaState get state => _state;

  Future<void> loadAll() async {
    _emit(_state.copyWith(loading: true, clearMessage: true));
    try {
      final summary = await _repository.getDashboard();
      final pacientes = await _repository.getPatients();
      final invitations = await _repository.getInvitations();
      final templates = await _repository.getTemplates();
      final settings = await _repository.getSettings();
      final foods = await _repository.getFoods();
      final tasks = await _repository.getTasks();
      _emit(
        _state.copyWith(
          loading: false,
          summary: summary,
          pacientes: pacientes,
          invitations: invitations,
          templates: templates,
          settings: settings,
          foods: foods,
          tasks: tasks,
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
      final consultations = await _repository.getConsultations(id);

      _emit(
        _state.copyWith(
          selectedPatient: patient,
          evaluations: evaluations,
          plans: plans,
          appointments: appointments,
          messages: messages,
          payments: payments,
          documents: documents,
          consultations: consultations,
        ),
      );
      final token = await _sessionManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        await _chat.connect(token: token, patientId: id);
        _messageSubscription ??= _chat.messages.listen(_onRealtimeMessage);
      }
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

  Future<void> createInvitation(String correo) async {
    _setBusy(true);
    try {
      await _repository.createInvitation(correo.trim());
      final invitations = await _repository.getInvitations();
      _emit(_state.copyWith(
          loading: false,
          invitations: invitations,
          message: 'Invitación enviada'));
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
    String fecha, {
    double cintura = 0,
    double cadera = 0,
    double brazo = 0,
    String plieguesCutaneos = '',
    double porcentajeMusculo = 0,
  }) async {
    _setBusy(true);
    try {
      await _repository.createEvaluation(patientId, peso, altura, grasa, fecha,
          cintura: cintura,
          cadera: cadera,
          brazo: brazo,
          plieguesCutaneos: plieguesCutaneos,
          porcentajeMusculo: porcentajeMusculo);
      await selectPatient(patientId);
      await loadAll();
      _emit(_state.copyWith(message: 'Evaluación registrada'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> updateEvaluation(int patientId, Evaluacion evaluation) async {
    _setBusy(true);
    try {
      await _repository.updateEvaluation(patientId, evaluation);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Evaluación actualizada'));
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

  Future<void> updatePlan(int patientId, PlanAlimenticio plan) async {
    _setBusy(true);
    try {
      await _repository.updatePlan(patientId, plan);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Plan alimenticio actualizado'));
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

  Future<void> updateAppointment(
      int patientId, CitaPaciente appointment) async {
    _setBusy(true);
    try {
      await _repository.updateAppointment(patientId, appointment);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Cita actualizada'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addMessage(int patientId, MensajePaciente message) async {
    _setBusy(true);
    try {
      if (_chat.isConnected) {
        _chat.sendMessage(message.contenido);
        _emit(_state.copyWith(loading: false, message: 'Mensaje enviado'));
      } else {
        await _repository.createMessage(patientId, message);
        await selectPatient(patientId);
        _emit(_state.copyWith(message: 'Mensaje enviado'));
      }
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  void _onRealtimeMessage(MensajePaciente message) {
    if (_state.selectedPatient?.id != message.pacienteId ||
        _state.messages.any((item) => item.id == message.id)) {
      return;
    }
    _emit(_state.copyWith(messages: [..._state.messages, message]));
    if (message.remitente == 'paciente') _chat.markRead(message.id);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _chat.disconnect();
    super.dispose();
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

  Future<void> updatePayment(int patientId, PagoPaciente payment) async {
    _setBusy(true);
    try {
      await _repository.updatePayment(patientId, payment);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Pago actualizado'));
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

  Future<void> uploadDocument(int patientId, String filePath,
      {String? nombre}) async {
    _setBusy(true);
    try {
      await _repository.uploadDocument(patientId, filePath, nombre: nombre);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Archivo subido correctamente'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> addConsultation(int patientId, Consulta consultation) async {
    _setBusy(true);
    try {
      await _repository.createConsultation(patientId, consultation);
      await selectPatient(patientId);
      _emit(_state.copyWith(message: 'Consulta registrada'));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> createTask(TareaNutricionista task) async {
    _setBusy(true);
    try {
      final created = await _repository.createTask(task);
      _emit(_state.copyWith(
        loading: false,
        tasks: [..._state.tasks, created],
        message: 'Tarea guardada',
      ));
    } catch (error) {
      _emit(_state.copyWith(loading: false, message: _message(error)));
    }
  }

  Future<void> updateTask(TareaNutricionista task) async {
    try {
      final updated = await _repository.updateTask(task);
      _emit(_state.copyWith(
        tasks: [
          for (final item in _state.tasks)
            if (item.id == updated.id) updated else item,
        ],
        message: 'Tarea actualizada',
      ));
    } catch (error) {
      _emit(_state.copyWith(message: _message(error)));
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
