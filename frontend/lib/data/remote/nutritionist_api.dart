import 'package:dio/dio.dart';

import '../dto/nutritionist_dtos.dart';

class NutritionistApi {
  NutritionistApi(this._dio);

  final Dio _dio;

  Future<DashboardDto> getDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>('/nutricionista/dashboard');
    return DashboardDto.fromJson(response.data ?? {});
  }

  Future<List<PatientDto>> getPatients() async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PatientDto.fromJson)
        .toList();
  }

  Future<PatientDto> createPatient(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes',
      data: body,
    );
    return PatientDto.fromJson(response.data ?? {});
  }

  Future<PatientDto> updatePatient(int id, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/nutricionista/pacientes/$id',
      data: body,
    );
    return PatientDto.fromJson(response.data ?? {});
  }

  Future<PatientDto> getPatient(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/nutricionista/pacientes/$id');
    return PatientDto.fromJson(response.data ?? {});
  }

  Future<List<EvaluationDto>> getEvaluations(int patientId) async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes/$patientId/evaluaciones');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(EvaluationDto.fromJson)
        .toList();
  }

  Future<EvaluationDto> createEvaluation(int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/evaluaciones',
      data: body,
    );
    return EvaluationDto.fromJson(response.data ?? {});
  }

  Future<List<PlanDto>> getPlans(int patientId) async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes/$patientId/planes');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlanDto.fromJson)
        .toList();
  }

  Future<PlanDto> createPlan(int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/planes',
      data: body,
    );
    return PlanDto.fromJson(response.data ?? {});
  }

  Future<List<AppointmentDto>> getAppointments(int patientId) async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes/$patientId/citas');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AppointmentDto.fromJson)
        .toList();
  }

  Future<AppointmentDto> createAppointment(int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/citas',
      data: body,
    );
    return AppointmentDto.fromJson(response.data ?? {});
  }

  Future<List<MessageDto>> getMessages(int patientId) async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes/$patientId/mensajes');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MessageDto.fromJson)
        .toList();
  }

  Future<MessageDto> createMessage(int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/mensajes',
      data: body,
    );
    return MessageDto.fromJson(response.data ?? {});
  }

  Future<List<PaymentDto>> getPayments(int patientId) async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes/$patientId/pagos');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PaymentDto.fromJson)
        .toList();
  }

  Future<PaymentDto> createPayment(int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/pagos',
      data: body,
    );
    return PaymentDto.fromJson(response.data ?? {});
  }

  Future<List<DocumentDto>> getDocuments(int patientId) async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes/$patientId/documentos');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DocumentDto.fromJson)
        .toList();
  }

  Future<DocumentDto> createDocument(int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/documentos',
      data: body,
    );
    return DocumentDto.fromJson(response.data ?? {});
  }

  Future<List<TemplateDto>> getTemplates() async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/plantillas');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TemplateDto.fromJson)
        .toList();
  }

  Future<TemplateDto> createTemplate(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/plantillas',
      data: body,
    );
    return TemplateDto.fromJson(response.data ?? {});
  }

  Future<SettingsDto> getSettings() async {
    final response = await _dio.get<Map<String, dynamic>>('/nutricionista/configuracion');
    return SettingsDto.fromJson(response.data ?? {});
  }

  Future<SettingsDto> updateSettings(Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/nutricionista/configuracion',
      data: body,
    );
    return SettingsDto.fromJson(response.data ?? {});
  }
}

