import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class SakuSkillApp extends StatelessWidget {
  const SakuSkillApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: MaterialApp(
        title: 'SakuSkill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.shell,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
