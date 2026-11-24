import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class SakuSkillApp extends StatelessWidget {
  const SakuSkillApp({
    super.key,
    required this.dependencies,
    this.initialRoute = AppRoutes.welcome,
  });

  final AppDependencies dependencies;

  /// Layar pembuka. Default "Awalan"; test memakai [AppRoutes.shell].
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: MaterialApp(
        title: 'SakuSkill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        ),
        initialRoute: initialRoute,
        onGenerateInitialRoutes: (name) => [
          AppRouter.onGenerateRoute(RouteSettings(name: name)),
        ],
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
