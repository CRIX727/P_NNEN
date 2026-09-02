import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/entities/user_role.dart';

class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).state.session;
    final authController = ref.read(authControllerProvider);

    final title = role == UserRole.nutricionista
        ? 'Panel Nutricionista'
        : 'Panel Paciente';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () async => authController.logout(),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Bienvenido${session != null ? ', ${session.name}' : ''}.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta es la base inicial del panel. En la siguiente fase se construirá la experiencia completa.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

