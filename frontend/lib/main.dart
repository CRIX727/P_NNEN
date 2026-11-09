import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/nnen_app.dart';
import 'core/services/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderService.instance.initialize();
  runApp(
    const ProviderScope(
      child: NnenApp(),
    ),
  );
}
