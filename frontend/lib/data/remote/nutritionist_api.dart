import 'package:dio/dio.dart';

import '../dto/nutritionist_dtos.dart';

class NutritionistApi {
  NutritionistApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getFoods() async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/alimentos');
    return (response.data ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createFood(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/alimentos',
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> uploadDocument(
      int patientId, String filePath, String? nombre) async {
    final file = await MultipartFile.fromFile(filePath);
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/documentos/upload',
      data: FormData.fromMap({
        'archivo': file,
        if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
      }),
    );
    return response.data ?? {};
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/tareas');
    return (response.data ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/tareas',
      data: body,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> updateTask(
      int id, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/nutricionista/tareas/$id',
      data: body,
    );
    return response.data ?? {};
  }

  Future<List<Map<String, dynamic>>> getConsultations(int patientId) async {
    final response = await _dio
        .get<List<dynamic>>('/nutricionista/pacientes/$patientId/consultas');
    return (response.data ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createConsultation(
      int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/consultas',
      data: body,
    );
    return response.data ?? {};
  }

  Future<DashboardDto> getDashboard() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/nutricionista/dashboard');
    return DashboardDto.fromJson(response.data ?? {});
  }

  Future<List<PatientDto>> getPatients() async {
    final response = await _dio.get<List<dynamic>>('/nutricionista/pacientes');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PatientDto.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getInvitations() async {
    final response =
        await _dio.get<List<dynamic>>('/nutricionista/invitaciones');
    return (response.data ?? []).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createInvitation(String correo) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/invitaciones',
      data: {'correo': correo},
    );
    return response.data ?? {};
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
    final response =
        await _dio.get<Map<String, dynamic>>('/nutricionista/pacientes/$id');
    return PatientDto.fromJson(response.data ?? {});
  }

  Future<List<EvaluationDto>> getEvaluations(int patientId) async {
    final response = await _dio
        .get<List<dynamic>>('/nutricionista/pacientes/$patientId/evaluaciones');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(EvaluationDto.fromJson)
        .toList();
  }

  Future<EvaluationDto> createEvaluation(
      int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/evaluaciones',
      data: body,
    );
    return EvaluationDto.fromJson(response.data ?? {});
  }

  Future<EvaluationDto> updateEvaluation(
      int patientId, int evaluationId, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/evaluaciones/$evaluationId',
      data: body,
    );
    return EvaluationDto.fromJson(response.data ?? {});
  }

  Future<List<PlanDto>> getPlans(int patientId) async {
    final response = await _dio
        .get<List<dynamic>>('/nutricionista/pacientes/$patientId/planes');
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

  Future<PlanDto> updatePlan(
      int patientId, int planId, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/planes/$planId',
      data: body,
    );
    return PlanDto.fromJson(response.data ?? {});
  }

  Future<List<AppointmentDto>> getAppointments(int patientId) async {
    final response = await _dio
        .get<List<dynamic>>('/nutricionista/pacientes/$patientId/citas');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AppointmentDto.fromJson)
        .toList();
  }

  Future<AppointmentDto> createAppointment(
      int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/citas',
      data: body,
    );
    return AppointmentDto.fromJson(response.data ?? {});
  }

  Future<AppointmentDto> updateAppointment(
      int patientId, int appointmentId, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/citas/$appointmentId',
      data: body,
    );
    return AppointmentDto.fromJson(response.data ?? {});
  }

  Future<List<MessageDto>> getMessages(int patientId) async {
    final response = await _dio
        .get<List<dynamic>>('/nutricionista/pacientes/$patientId/mensajes');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MessageDto.fromJson)
        .toList();
  }

  Future<MessageDto> createMessage(
      int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/mensajes',
      data: body,
    );
    return MessageDto.fromJson(response.data ?? {});
  }

  Future<List<PaymentDto>> getPayments(int patientId) async {
    final response = await _dio
        .get<List<dynamic>>('/nutricionista/pacientes/$patientId/pagos');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PaymentDto.fromJson)
        .toList();
  }

  Future<PaymentDto> createPayment(
      int patientId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/pagos',
      data: body,
    );
    return PaymentDto.fromJson(response.data ?? {});
  }

  Future<PaymentDto> updatePayment(
      int patientId, int paymentId, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/nutricionista/pacientes/$patientId/pagos/$paymentId',
      data: body,
    );
    return PaymentDto.fromJson(response.data ?? {});
  }

  Future<List<DocumentDto>> getDocuments(int patientId) async {
    final response = await _dio
        .get<List<dynamic>>('/nutricionista/pacientes/$patientId/documentos');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DocumentDto.fromJson)
        .toList();
  }

  Future<DocumentDto> createDocument(
      int patientId, Map<String, dynamic> body) async {
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
    final response =
        await _dio.get<Map<String, dynamic>>('/nutricionista/configuracion');
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
