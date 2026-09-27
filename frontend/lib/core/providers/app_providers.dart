import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/api_client.dart';
import '../../data/remote/auth_api.dart';
import '../../data/remote/chat_socket_service.dart';
import '../../data/remote/nutritionist_api.dart';
import '../../data/remote/patient_api.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/nutritionist_repository.dart';
import '../../data/repositories/nutritionist_repository_impl.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/patient_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/load_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_session_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../presentation/auth/auth_controller.dart';
import '../../presentation/nutricionista/nutricionista_controller.dart';
import '../../presentation/paciente/paciente_controller.dart';
import '../services/session_manager.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

final dioProvider = Provider<Dio>((ref) {
  return ApiClient.create(ref.watch(sessionManagerProvider));
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    authApi: ref.watch(authApiProvider),
    sessionManager: ref.watch(sessionManagerProvider),
  );
});

final loadSessionUseCaseProvider = Provider<LoadSessionUseCase>((ref) {
  return LoadSessionUseCase(ref.watch(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final refreshSessionUseCaseProvider = Provider<RefreshSessionUseCase>((ref) {
  return RefreshSessionUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    loadSessionUseCase: ref.watch(loadSessionUseCaseProvider),
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    refreshSessionUseCase: ref.watch(refreshSessionUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
  );
  controller.bootstrap();
  return controller;
});

final nutritionistApiProvider = Provider<NutritionistApi>((ref) {
  return NutritionistApi(ref.watch(dioProvider));
});

final nutritionistRepositoryProvider = Provider<NutritionistRepository>((ref) {
  return NutritionistRepositoryImpl(ref.watch(nutritionistApiProvider));
});

final nutritionistControllerProvider = ChangeNotifierProvider<NutricionistaController>((ref) {
  final controller = NutricionistaController(
    ref.watch(nutritionistRepositoryProvider),
    ref.watch(chatSocketServiceProvider),
    ref.watch(sessionManagerProvider),
  );
  return controller;
});

final patientApiProvider = Provider<PatientApi>((ref) {
  return PatientApi(ref.watch(dioProvider));
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService();
  ref.onDispose(service.dispose);
  return service;
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepositoryImpl(ref.watch(patientApiProvider));
});

final patientControllerProvider = ChangeNotifierProvider<PacienteController>((ref) {
  return PacienteController(
    ref.watch(patientRepositoryProvider),
    ref.watch(chatSocketServiceProvider),
    ref.watch(sessionManagerProvider),
  );
});
