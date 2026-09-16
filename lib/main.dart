import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'models.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final settings = SharedPreferencesAsync();
  late Future<(AtlasData, AppLanguage)> ready = load();

  Future<(AtlasData, AppLanguage)> load() async {
    final data = await AtlasData.load();
    var language = AppLanguage.en;
    try {
      if (await settings.getString('language') == 'es') {
        language = AppLanguage.es;
      }
    } catch (_) {
      // Local preferences are optional; they must never block offline exploration.
    }
    return (data, language);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: ready,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final (data, language) = snapshot.requireData;
        return AtlasApp(
          data: data,
          initialLanguage: language,
          persistLanguage: (value) =>
              settings.setString('language', value.name),
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: atlasTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'We couldn’t open the atlas. Try again.\nNo pudimos abrir el atlas. Intenta de nuevo.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => setState(() => ready = load()),
                          child: const Text('Retry / Reintentar'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(color: forest),
            ),
          ),
        ),
      );
    },
  );
}
