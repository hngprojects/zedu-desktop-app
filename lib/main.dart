import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/app/app.dart';
import 'package:zedu/core/core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadAppEnv();
  setupLocator();

  runApp(const ProviderScope(child: App()));
}
