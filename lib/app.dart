import 'package:flutter/material.dart';
import 'controllers/theme_controller.dart';
import 'screens/generator/pix_generator_screen.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  final ThemeController themeController;

  const App({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (_, __) => MaterialApp(
        title: 'QR PIX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeController.mode,
        home: PixGeneratorScreen(themeController: themeController),
      ),
    );
  }
}
