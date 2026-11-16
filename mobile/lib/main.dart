import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SakuSkillApp(dependencies: AppDependencies.production()));
}
