import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/app_config.dart';
import '../../domain/entities/mensaje_paciente.dart';
import '../dto/nutritionist_dtos.dart';

class ChatSocketService {
  io.Socket? _socket;
  final _messages = StreamController<MensajePaciente>.broadcast();
  final _errors = StreamController<String>.broadcast();

  Stream<MensajePaciente> get messages => _messages.stream;
  Stream<String> get errors => _errors.stream;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({required String token, required int patientId}) async {
    disconnect();
    final apiUrl = AppConfig.apiBaseUrl;
    final baseUrl = apiUrl.endsWith('/api')
        ? apiUrl.substring(0, apiUrl.length - 4)
        : apiUrl;
    final socket = io.io(
      '$baseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket = socket;
    socket.onConnect((_) {
      socket.emit('join_conversation', {'pacienteId': patientId});
    });
    socket.on('message_received', (data) {
      if (data is Map) {
        _messages.add(MessageDto.fromJson(Map<String, dynamic>.from(data)).toEntity());
      }
    });
    socket.on('chat_error', (data) {
      _errors.add(data?.toString() ?? 'No se pudo conectar al chat');
    });
    socket.onConnectError((_) {
      _errors.add('El chat en tiempo real no está disponible');
    });
    socket.connect();
  }

  void sendMessage(String content) {
    if (isConnected) _socket!.emit('send_message', {'contenido': content});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messages.close();
    _errors.close();
  }
}
