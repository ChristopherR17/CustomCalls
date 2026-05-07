import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'app_data.dart';

void main() async {
  try {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      WidgetsFlutterBinding.ensureInitialized();
      await WindowManager.instance.ensureInitialized();
      windowManager.waitUntilReadyToShow().then(showWindow);
    }
  } catch (e) {
    // ignore: avoid_print
    print(e);
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppData(),
      child: const App(),
    ),
  );
}

void showWindow(_) async {
  windowManager.setMinimumSize(const Size(900, 600));
  await windowManager.setTitle('Dibuix vectorial amb IA');
  await windowManager.show();
  await windowManager.focus();
}
