import 'package:flutter/material.dart';

import './app/app.dart';
import './app/theme/theme_provider.dart';
import './core/network/api_client.dart';

export './app/app.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  runApp(MyApp(initialThemeMode: await ThemeProvider.loadSaved()));
}
