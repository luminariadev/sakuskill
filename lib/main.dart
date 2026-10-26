import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/services/presentation/providers/app_state_provider.dart';
import 'features/services/presentation/pages/home_discovery_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SakuSkillMobileApp());
}

class SakuSkillMobileApp extends StatelessWidget {
  const SakuSkillMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: MaterialApp(
        title: 'SakuSkill Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Consumer<AppStateProvider>(
          builder: (context, appState, _) {
            if (appState.isAuthenticated) {
              return const HomeDiscoveryPage();
            }
            return const AuthPage();
          },
        ),
      ),
    );
  }
}
