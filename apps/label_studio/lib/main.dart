import 'package:flutter/material.dart';

import 'src/library/library_repository.dart';
import 'src/library/library_screen.dart';

void main() => runApp(const LabelStudioApp());

/// Configura, gera, salva e imprime etiquetas para uso por aplicações
/// externas — ver `docs/ARCHITECTURE.md` seção 20 e `docs/INTEGRATION.md`.
/// Único ponto de composição de negócio deste app; tudo que edita/renderiza
/// etiquetas vem de `label_designer_kit`.
class LabelStudioApp extends StatelessWidget {
  const LabelStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label Studio',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: FutureBuilder<LibraryRepository>(
        future: LibraryRepository.open(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            final error = snapshot.error;
            if (error != null) {
              return Scaffold(
                body: Center(child: Text('Falha ao abrir a biblioteca: $error')),
              );
            }
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return LibraryScreen(repository: snapshot.data!);
        },
      ),
    );
  }
}
