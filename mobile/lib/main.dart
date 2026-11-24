import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/app_dependencies.dart';
import 'core/navigation/app_router.dart';
import 'core/storage/session_store.dart' as secure;
import 'features/auth/data/auth_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionStore = secure.SecureSessionStore();
  if (!AppConfig.useMockData) {
    await AuthSession.instance.restore(sessionStore);
  }
  runApp(
    SakuSkillApp(
      dependencies: AppDependencies.production(sessionStore: sessionStore),
      initialRoute: AuthSession.instance.isLoggedIn
          ? AppRoutes.shell
          : AppRoutes.welcome,
    ),
  );
}
