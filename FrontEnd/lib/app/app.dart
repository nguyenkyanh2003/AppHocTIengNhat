import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/providers/auth_provider.dart';
import './app_providers.dart';
import './localization/app_localizations.dart';
import './localization/locale_provider.dart';
import './router/app_router.dart';
import './theme/app_scroll_behavior.dart';
import './theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: createAppProviders(),
      child: const _AppView(),
    );
  }
}

/// Dựng `GoRouter` **một lần** rồi giữ nguyên suốt vòng đời ứng dụng.
///
/// Router phải ổn định: dựng lại nó ở mỗi lần `build` sẽ xoá sạch lịch sử
/// điều hướng và trạng thái của từng nhánh mỗi khi `AuthProvider` phát tín
/// hiệu — tức là mỗi lần cập nhật hồ sơ hay đổi mật khẩu. Thay đổi đăng nhập
/// và quyền được truyền vào qua `refreshListenable`, chỉ khiến router **tính
/// lại redirect** chứ không dựng lại cây điều hướng.
class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.create(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp.router(
      title: 'App Học Tiếng Nhật',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
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
      routerConfig: _router,
    );
  }
}
