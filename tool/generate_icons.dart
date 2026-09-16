// Run with: flutter test tool/generate_icons.dart
// Renders original vector branding into the generated platform icon slots.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

Future<void> renderIcon(String destination, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..scale(size / 1024);
  canvas.drawColor(const ui.Color(0xFF28664F), ui.BlendMode.src);
  final paint = ui.Paint()
    ..color = const ui.Color(0xFFF8E8AE)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 22
    ..strokeCap = ui.StrokeCap.round;
  const center = ui.Offset(512, 512);
  canvas.drawCircle(center, 294, paint);
  canvas.drawOval(const ui.Rect.fromLTWH(365, 218, 294, 588), paint);
  canvas.drawLine(const ui.Offset(226, 512), const ui.Offset(798, 512), paint);
  canvas.drawArc(
    const ui.Rect.fromLTWH(245, 256, 534, 170),
    0,
    3.14159265,
    false,
    paint,
  );
  canvas.drawArc(
    const ui.Rect.fromLTWH(245, 598, 534, 170),
    3.14159265,
    3.14159265,
    false,
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(destination).writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
}

void main() {
  test('render app and preview icons', () async {
    const iconDirectory = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final manifest = jsonDecode(
      await File('$iconDirectory/Contents.json').readAsString(),
    );
    for (final item in manifest['images']) {
      final filename = item['filename'] as String?;
      if (filename == null) continue;
      if (!RegExp(r'^Icon-App-[\w@.-]+\.png$').hasMatch(filename)) {
        throw StateError('Unexpected icon output path');
      }
      final points = double.parse((item['size'] as String).split('x').first);
      final scale = double.parse((item['scale'] as String).replaceAll('x', ''));
      await renderIcon('$iconDirectory/$filename', (points * scale).round());
    }
    for (final size in [192, 512]) {
      await renderIcon('web/icons/Icon-$size.png', size);
      await renderIcon('web/icons/Icon-maskable-$size.png', size);
    }
    await renderIcon('web/favicon.png', 32);
  });
}
