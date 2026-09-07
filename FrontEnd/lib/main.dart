import 'package:flutter/material.dart';

import './app/app.dart';
import './core/network/api_client.dart';

export './app/app.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  runApp(const MyApp());
}
