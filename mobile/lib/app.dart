import 'dart:async';

import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_session.dart';

class SakuSkillApp extends StatefulWidget {
  const SakuSkillApp({
    super.key,
    required this.dependencies,
    this.initialRoute = AppRoutes.welcome,
  });

  final AppDependencies dependencies;

  /// Layar pembuka. Default "Awalan"; test memakai [AppRoutes.shell].
  final String initialRoute;

  @override
  State<SakuSkillApp> createState() => _SakuSkillAppState();
}

class _SakuSkillAppState extends State<SakuSkillApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<void>? _unauthSub;

  @override
  void initState() {
    super.initState();
    _unauthSub = AuthSession.instance.onUnauthorized.listen(_handleUnauthorized);
  }

  void _handleUnauthorized(void _) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Sesi Anda telah berakhir. Silakan masuk kembali.'),
      ),
    );
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  void dispose() {
    _unauthSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: widget.dependencies,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'SakuSkill',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        ),
        initialRoute: widget.initialRoute,
        onGenerateInitialRoutes: (name) => [
          AppRouter.onGenerateRoute(RouteSettings(name: name)),
        ],
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
