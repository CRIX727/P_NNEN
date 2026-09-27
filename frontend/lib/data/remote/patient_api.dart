import 'package:dio/dio.dart';

import '../dto/nutritionist_dtos.dart';

class PatientApi {
  PatientApi(this._dio);

  final Dio _dio;

  Future<PatientProfileDto> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/paciente/perfil');
    return PatientProfileDto.fromJson(response.data ?? {});
  }

  Future<List<EvaluationDto>> getEvaluations() async {
    final response = await _dio.get<List<dynamic>>('/paciente/evaluaciones');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(EvaluationDto.fromJson)
        .toList();
  }

  Future<List<PlanDto>> getPlans() async {
    final response = await _dio.get<List<dynamic>>('/paciente/planes');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlanDto.fromJson)
        .toList();
  }

  Future<List<AppointmentDto>> getAppointments() async {
    final response = await _dio.get<List<dynamic>>('/paciente/citas');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AppointmentDto.fromJson)
        .toList();
  }

  Future<List<MessageDto>> getMessages() async {
    final response = await _dio.get<List<dynamic>>('/paciente/mensajes');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MessageDto.fromJson)
        .toList();
  }

  Future<MessageDto> sendMessage(String contenido) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/paciente/mensajes',
      data: {'contenido': contenido},
    );
    return MessageDto.fromJson(response.data ?? {});
  }

  Future<List<PaymentDto>> getPayments() async {
    final response = await _dio.get<List<dynamic>>('/paciente/pagos');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PaymentDto.fromJson)
        .toList();
  }

  Future<List<DocumentDto>> getDocuments() async {
    final response = await _dio.get<List<dynamic>>('/paciente/documentos');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DocumentDto.fromJson)
        .toList();
  }
}

class PatientProfileDto {
  const PatientProfileDto({
    required this.patient,
    required this.nutritionistName,
    required this.nutritionistEmail,
    required this.nutritionistWhatsapp,
  });

  factory PatientProfileDto.fromJson(Map<String, dynamic> json) {
    final nutritionist = json['nutricionista'] as Map<String, dynamic>? ?? {};
    return PatientProfileDto(
      patient: PatientDto.fromJson(
        json['paciente'] as Map<String, dynamic>? ?? {},
      ),
      nutritionistName: nutritionist['nombre'] as String? ?? 'Tu nutricionista',
      nutritionistEmail: nutritionist['correo'] as String? ?? '',
      nutritionistWhatsapp: nutritionist['whatsapp'] as String? ?? '',
    );
  }

  final PatientDto patient;
  final String nutritionistName;
  final String nutritionistEmail;
  final String nutritionistWhatsapp;
}
