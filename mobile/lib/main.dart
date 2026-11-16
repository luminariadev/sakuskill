import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.production();
  // Pulihkan sesi tersimpan sebelum layar pertama (FE-03).
  await dependencies.init();
  runApp(SakuSkillApp(dependencies: dependencies));
}
