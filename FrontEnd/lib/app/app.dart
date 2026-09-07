import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import './localization/app_localizations.dart';
import '../features/auth/providers/auth_provider.dart';
import './localization/locale_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import './app_providers.dart';
import './router/app_router.dart';
import './theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: createAppProviders(),
      child: Consumer2<AuthProvider, LocaleProvider>(
        builder: (context, authProvider, localeProvider, _) {
          return MaterialApp(
            title: 'App Học Tiếng Nhật',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('vi', 'VN'),
              Locale('en', 'US'),
              Locale('ja', 'JP'),
            ],
            routes: AppRouter.routes,
            onGenerateRoute: AppRouter.onGenerateRoute,
            onUnknownRoute: AppRouter.onUnknownRoute,
            home: authProvider.isLoading
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : authProvider.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen(),
          );
        },
      ),
    );
  }
}
