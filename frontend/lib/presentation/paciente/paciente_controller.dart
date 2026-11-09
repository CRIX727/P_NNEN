import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/session_manager.dart';
import '../../core/services/reminder_service.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/remote/chat_socket_service.dart';
import '../../domain/entities/cita_paciente.dart';
import '../../domain/entities/documento_paciente.dart';
import '../../domain/entities/evaluacion.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../../domain/entities/pago_paciente.dart';
import '../../domain/entities/plan_alimenticio.dart';
import 'paciente_state.dart';

class PacienteController extends ChangeNotifier {
  PacienteController(this._repository, this._chat, this._sessionManager);

  final PatientRepository _repository;
  final ChatSocketService _chat;
  final SessionManager _sessionManager;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _chatErrorSubscription;
  PacienteState _state = const PacienteState.initial();

  PacienteState get state => _state;

  Future<void> load() async {
    if (_state.isLoading) return;
    _emit(
        _state.copyWith(isLoading: true, clearError: true, clearMessage: true));
    try {
      final profile = await _repository.getProfile();
      final invitations = await _repository.getInvitations();
      final notifications = await _repository.getNotifications();
      final consultations = await _repository.getConsultations();
      final subscription = await _repository.getSubscription();
      final token = await _sessionManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        await _chat.connect(token: token, patientId: profile.paciente.id);
        _messageSubscription ??= _chat.messages.listen(_onRealtimeMessage);
        _chatErrorSubscription ??= _chat.errors.listen((error) {
          _emit(_state.copyWith(error: error));
        });
      }
      final results = await Future.wait<Object>([
        _repository.getEvaluations(),
        _repository.getPlans(),
        _repository.getAppointments(),
        _repository.getMessages(),
        _repository.getPayments(),
        _repository.getDocuments(),
      ]);
      _emit(
        _state.copyWith(
          profile: profile,
          invitations: invitations,
          evaluaciones: results[0] as List<Evaluacion>,
          planes: results[1] as List<PlanAlimenticio>,
          citas: results[2] as List<CitaPaciente>,
          mensajes: results[3] as List<MensajePaciente>,
          pagos: results[4] as List<PagoPaciente>,
          documentos: results[5] as List<DocumentoPaciente>,
          notificaciones: notifications,
          consultas: consultations,
          suscripcion: subscription,
          isLoading: false,
        ),
      );
      for (final appointment in results[2] as List<CitaPaciente>) {
        final date =
            DateTime.tryParse(appointment.fecha.replaceFirst(' ', 'T'));
        if (date != null && date.isAfter(DateTime.now())) {
          await ReminderService.instance.scheduleAppointment(
            id: 1000 + appointment.id,
            appointment: date,
          );
        }
      }
    } catch (error) {
      _emit(_state.copyWith(isLoading: false, error: _messageFrom(error)));
    }
  }

  void setSection(PacienteSection section) {
    _emit(_state.copyWith(section: section, clearMessage: true));
  }

  Future<void> acceptInvitation(int id) async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.acceptInvitation(id);
      await load();
      _emit(_state.copyWith(
          message: 'Ahora eres paciente de este nutricionista'));
    } catch (error) {
      _emit(_state.copyWith(isLoading: false, error: _messageFrom(error)));
    }
  }

  Future<void> rejectInvitation(int id) async {
    try {
      await _repository.rejectInvitation(id);
      final invitations = await _repository.getInvitations();
      _emit(_state.copyWith(
          invitations: invitations, message: 'Invitación rechazada'));
    } catch (error) {
      _emit(_state.copyWith(error: _messageFrom(error)));
    }
  }

  Future<void> createSubscription(String plan) async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final subscription = await _repository.createSubscription(plan);
      _emit(_state.copyWith(
          isLoading: false,
          suscripcion: subscription,
          message: 'Suscripción actualizada'));
    } catch (error) {
      _emit(_state.copyWith(isLoading: false, error: _messageFrom(error)));
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _state.isSending) return;
    _emit(_state.copyWith(isSending: true, clearError: true));
    try {
      if (_chat.isConnected) {
        _chat.sendMessage(trimmed);
        _emit(_state.copyWith(isSending: false, message: 'Mensaje enviado'));
      } else {
        final message = await _repository.sendMessage(trimmed);
        _emit(_state.copyWith(
            mensajes: [..._state.mensajes, message],
            isSending: false,
            message: 'Mensaje enviado'));
      }
    } catch (error) {
      _emit(_state.copyWith(isSending: false, error: _messageFrom(error)));
    }
  }

  void _onRealtimeMessage(MensajePaciente message) {
    if (_state.mensajes.any((item) => item.id == message.id)) return;
    _emit(_state.copyWith(mensajes: [..._state.mensajes, message]));
    if (message.remitente != 'paciente') _chat.markRead(message.id);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _chatErrorSubscription?.cancel();
    _chat.disconnect();
    super.dispose();
  }

  void _emit(PacienteState state) {
    _state = state;
    notifyListeners();
  }

  String _messageFrom(Object error) {
    final message = error.toString();
    return message.contains('Exception:')
        ? message.replaceFirst('Exception:', '').trim()
        : message;
  }
}
