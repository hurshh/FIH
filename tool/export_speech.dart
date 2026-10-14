// Run with: flutter test tool/export_speech.dart
// Lists every part the app can read aloud, in both languages, as
// build/speech/manifest.tsv (key, language, text). tool/generate_speech.sh
// records a clip for each line.
import 'dart:io';

import 'package:americas_explorer/models.dart';
import 'package:americas_explorer/speech_script.dart';
import 'package:americas_explorer/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export speech manifest', () async {
    final data = await AtlasData.load();
    final lines = <String>{};
    for (final language in AppLanguage.values) {
      for (final part in allSpeech(data, Strings(language))) {
        final text = forSpeech(part, language);
        lines.add('${speechKey(language, part)}\t${language.name}\t$text');
      }
    }
    File('build/speech/manifest.tsv')
      ..createSync(recursive: true)
      ..writeAsStringSync('${(lines.toList()..sort()).join('\n')}\n');
    // ignore: avoid_print
    print('Exported ${lines.length} speech parts.');
  });
}
