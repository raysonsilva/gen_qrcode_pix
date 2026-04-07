import 'package:flutter/material.dart';
import 'app.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.init();
  runApp(App(themeController: themeController));
}
