import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_role.dart';
import '../../presentation/auth/auth_state.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/home/role_home_screen.dart';
import '../../presentation/nutricionista/nutricionista_panel_screen.dart';
import '../../presentation/nutricionista/patient_detail_screen.dart';
import '../../presentation/splash/splash_screen.dart';
import '../providers/app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authController = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authController,
    redirect: (context, state) {
      final authState = authController.state;
      final location = state.matchedLocation;

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return location == '/splash' ? null : '/splash';
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (location == '/login' || location == '/register') {
          return null;
        }
        return '/login';
      }

      if (authState.status == AuthStatus.authenticated) {
        final roleRoute = authState.session?.role == UserRole.nutricionista
            ? '/nutricionista'
            : '/paciente';
        if (location == '/splash' || location == '/login' || location == '/register') {
          return roleRoute;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/nutricionista',
        builder: (context, state) => const NutritionistPanelScreen(),
        routes: [
          GoRoute(
            path: 'paciente/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id'] ?? '0');
              return PatientDetailScreen(patientId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/paciente',
        builder: (context, state) => const RoleHomeScreen(
          role: UserRole.paciente,
        ),
      ),
    ],
  );
});
