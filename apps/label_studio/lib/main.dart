import 'package:flutter/material.dart';

import 'src/library/library_repository.dart';
import 'src/library/library_screen.dart';

void main() => runApp(const LabelStudioApp());

/// Configura, gera, salva e imprime etiquetas para uso por aplicações
/// externas — ver `docs/ARCHITECTURE.md` seção 20 e `docs/INTEGRATION.md`.
/// Único ponto de composição de negócio deste app; tudo que edita/renderiza
/// etiquetas vem de `label_designer_kit`.
class LabelStudioApp extends StatefulWidget {
  const LabelStudioApp({super.key});

  @override
  State<LabelStudioApp> createState() => _LabelStudioAppState();
}

class _LabelStudioAppState extends State<LabelStudioApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _cycleThemeMode() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label Studio',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      home: FutureBuilder<LibraryRepository>(
        future: LibraryRepository.open(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            final error = snapshot.error;
            if (error != null) {
              return Scaffold(
                body: Center(
                  child: Text('Falha ao abrir a biblioteca: $error'),
                ),
              );
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return LibraryScreen(
            repository: snapshot.data!,
            themeMode: _themeMode,
            onToggleThemeMode: _cycleThemeMode,
          );
        },
      ),
    );
  }
}
