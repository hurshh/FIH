import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Original vector illustrations, rendered locally at any screen resolution.
class DiscoveryArt extends StatelessWidget {
  const DiscoveryArt({super.key, this.scene = 'toucan', this.height = 220});
  final String scene;
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ArtPainter(scene)),
    ),
  );
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter(this.scene);
  final String scene;
  void oval(Canvas c, Rect r, Color color) =>
      c.drawOval(r, Paint()..color = color);
  void stroke(Canvas c, List<Offset> points, Color color, double width) {
    final path = Path()..addPolygon(points, false);
    c.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void leaf(
    Canvas c,
    double x,
    double y,
    double rotation,
    double scale,
    Color color,
  ) {
    c.save();
    c.translate(x, y);
    c.rotate(rotation);
    c.scale(scale);
    final p = Path()
      ..moveTo(0, 0)
      ..cubicTo(-28, -15, -27, -54, 0, -77)
      ..cubicTo(28, -51, 25, -16, 0, 0);
    c.drawPath(p, Paint()..color = color);
    stroke(
      c,
      [const Offset(0, -3), const Offset(0, -61)],
      color.withValues(alpha: .45),
      1.2,
    );
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(size.width / 360, size.height / 240);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 240),
      Paint()..color = const Color(0xFFEDF1DF),
    );
    c.drawCircle(
      const Offset(247, 68),
      42,
      Paint()..color = const Color(0xFFF3D58B),
    );
    final hill = Path()
      ..moveTo(0, 199)
      ..quadraticBezierTo(97, 139, 177, 191)
      ..quadraticBezierTo(265, 143, 360, 187)
      ..lineTo(360, 240)
      ..lineTo(0, 240)
      ..close();
    c.drawPath(hill, Paint()..color = const Color(0xFFD8E3C7));
    switch (scene) {
      case 'toucan':
        _toucan(c);
      case 'axolotl':
        _axolotl(c);
      case 'mountains':
        _mountains(c);
      case 'music':
        _music(c);
      case 'food':
        _food(c);
      case 'basketball':
        _basketball(c);
      default:
        _toucan(c);
    }
    leaf(c, 29, 253, -.25, 1.1, const Color(0xFF8BAE85));
    leaf(c, 29, 253, .53, .8, const Color(0xFF5C8F71));
    leaf(c, 332, 258, -.55, 1.0, const Color(0xFF9BBD8C));
    leaf(c, 332, 258, .32, 1.35, const Color(0xFF628E70));
    c.restore();
  }

  void _toucan(Canvas c) {
    stroke(
      c,
      [const Offset(41, 193), const Offset(302, 173)],
      const Color(0xFF9E7751),
      12,
    );
    stroke(
      c,
      [const Offset(284, 175), const Offset(314, 155)],
      const Color(0xFF9E7751),
      6,
    );
    leaf(c, 88, 189, -.9, .68, const Color(0xFF769B66));
    leaf(c, 288, 174, .65, .6, const Color(0xFF659773));
    final tail = Path()
      ..moveTo(156, 147)
      ..lineTo(126, 221)
      ..lineTo(161, 210)
      ..lineTo(189, 151)
      ..close();
    c.drawPath(tail, Paint()..color = ink);
    oval(c, const Rect.fromLTWH(140, 77, 88, 101), ink);
    oval(c, const Rect.fromLTWH(172, 84, 49, 74), const Color(0xFFFCF6DF));
    oval(c, const Rect.fromLTWH(143, 111, 52, 58), const Color(0xFF355A4A));
    c.drawCircle(const Offset(203, 79), 33, Paint()..color = ink);
    final beak = Path()
      ..moveTo(211, 61)
      ..cubicTo(256, 45, 300, 62, 307, 95)
      ..quadraticBezierTo(251, 105, 213, 91)
      ..close();
    c.drawPath(beak, Paint()..color = const Color(0xFFF0B34F));
    c.save();
    c.clipPath(beak);
    c.drawRect(const Rect.fromLTWH(269, 35, 50, 79), Paint()..color = coral);
    c.drawOval(const Rect.fromLTWH(290, 61, 28, 35), Paint()..color = ink);
    stroke(
      c,
      [const Offset(217, 87), const Offset(305, 92)],
      const Color(0xFFD08745),
      2,
    );
    c.restore();
    c.drawCircle(
      const Offset(202, 73),
      8,
      Paint()..color = const Color(0xFFA6C7BD),
    );
    c.drawCircle(const Offset(203, 72), 3.5, Paint()..color = ink);
    c.drawCircle(const Offset(204, 70.5), 1.2, Paint()..color = Colors.white);
    stroke(
      c,
      [const Offset(181, 173), const Offset(179, 184), const Offset(190, 184)],
      const Color(0xFFBA8746),
      4,
    );
    stroke(
      c,
      [const Offset(199, 168), const Offset(198, 183), const Offset(207, 182)],
      const Color(0xFFBA8746),
      4,
    );
    _spark(c, const Offset(101, 72), 8);
    _spark(c, const Offset(297, 124), 5);
  }

  void _axolotl(Canvas c) {
    c.drawRect(
      const Rect.fromLTWH(0, 122, 360, 118),
      Paint()..color = const Color(0xFFC5DDD7),
    );
    for (final x in [63.0, 289.0, 311.0]) {
      c.drawCircle(
        Offset(x, 125 - x % 43),
        5,
        Paint()..color = Colors.white.withValues(alpha: .7),
      );
    }
    final tail = Path()
      ..moveTo(191, 141)
      ..quadraticBezierTo(289, 178, 291, 107)
      ..quadraticBezierTo(320, 199, 197, 183)
      ..close();
    c.drawPath(tail, Paint()..color = const Color(0xFFE3A5AA));
    oval(c, const Rect.fromLTWH(127, 123, 121, 61), const Color(0xFFEDB8BD));
    for (final direction in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final x = 135 + direction * 46;
        final y = 115.0 + i * 10;
        stroke(
          c,
          [Offset(x, y), Offset(x + direction * 23, y - 27 + i * 12)],
          const Color(0xFFCC778B),
          7,
        );
      }
    }
    oval(c, const Rect.fromLTWH(85, 91, 104, 75), const Color(0xFFF3CCD0));
    for (final x in [113.0, 159.0]) {
      c.drawCircle(Offset(x, 125), 4, Paint()..color = ink);
      oval(c, Rect.fromLTWH(x - 8, 134, 14, 7), const Color(0xFFE49DAA));
    }
    c.drawArc(
      const Rect.fromLTWH(127, 129, 20, 14),
      0,
      math.pi,
      false,
      Paint()
        ..color = ink
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    stroke(
      c,
      [const Offset(146, 165), const Offset(134, 182), const Offset(148, 184)],
      const Color(0xFFD89AA4),
      8,
    );
    stroke(
      c,
      [const Offset(211, 169), const Offset(218, 184), const Offset(231, 182)],
      const Color(0xFFD89AA4),
      8,
    );
  }

  void _mountains(Canvas c) {
    for (final (x, y, width, color) in [
      (15.0, 68.0, 159.0, const Color(0xFF94B7A1)),
      (122.0, 42.0, 183.0, const Color(0xFF648E78)),
      (223.0, 105.0, 155.0, const Color(0xFFB1C69A)),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(x, 207)
          ..lineTo(x + width / 2, y)
          ..lineTo(x + width, 207)
          ..close(),
        Paint()..color = color,
      );
    }
    for (var i = 0; i < 5; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(105 - i * 11, 140 + i * 13, 92 + i * 24, 13),
          const Radius.circular(2),
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFC0C18C)
              : const Color(0xFF849F75),
      );
    }
    for (var i = 0; i < 3; i++) {
      c.drawRect(
        Rect.fromLTWH(128 + i * 25, 115, 19, 27),
        Paint()..color = const Color(0xFFD5C79A),
      );
    }
  }

  void _music(Canvas c) {
    c.save();
    c.translate(163, 140);
    c.rotate(.36);
    oval(c, const Rect.fromLTWH(-40, -17, 80, 83), coral);
    oval(c, const Rect.fromLTWH(-29, -44, 58, 70), const Color(0xFFE8AD68));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -112, 16, 99),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFA87A50),
    );
    c.drawCircle(const Offset(0, 2), 13, Paint()..color = ink);
    for (var i = -2; i <= 2; i++) {
      stroke(
        c,
        [Offset(i * 2.5, -106), Offset(i * 2.5, 41)],
        const Color(0xFFFBE5B7),
        1,
      );
    }
    c.restore();
    for (final p in [
      const Offset(80, 68),
      const Offset(259, 128),
      const Offset(270, 59),
    ]) {
      oval(c, Rect.fromCenter(center: p, width: 17, height: 12), forest);
      stroke(
        c,
        [
          p + const Offset(7, 0),
          p + const Offset(7, -31),
          p + const Offset(22, -26),
        ],
        forest,
        4,
      );
    }
  }

  void _food(Canvas c) {
    oval(c, const Rect.fromLTWH(73, 133, 219, 69), const Color(0xFFF9F4DC));
    oval(c, const Rect.fromLTWH(91, 147, 180, 39), const Color(0xFFDDD6B5));
    for (final (x, y, color) in [
      (102.0, 116.0, const Color(0xFFD3A166)),
      (160.0, 98.0, const Color(0xFFA385A6)),
      (197.0, 126.0, coral),
    ]) {
      oval(c, Rect.fromLTWH(x, y, 65, 45), color);
      for (var i = 0; i < 4; i++) {
        c.drawCircle(
          Offset(x + 15 + i * 11, y + 15 + (i % 2) * 12),
          2,
          Paint()..color = ink.withValues(alpha: .3),
        );
      }
    }
    _spark(c, const Offset(103, 73), 8);
  }

  void _basketball(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(210, 45, 82, 63),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFFCF7E5),
    );
    stroke(
      c,
      [const Offset(250, 106), const Offset(250, 195)],
      const Color(0xFF849C89),
      8,
    );
    c.drawRect(
      const Rect.fromLTWH(236, 67, 28, 23),
      Paint()
        ..color = coral
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    stroke(
      c,
      [
        const Offset(225, 99),
        const Offset(236, 130),
        const Offset(265, 130),
        const Offset(277, 99),
      ],
      const Color(0xFFAB8D63),
      3,
    );
    stroke(c, [const Offset(221, 97), const Offset(278, 97)], coral, 5);
    c.drawCircle(
      const Offset(135, 143),
      43,
      Paint()..color = const Color(0xFFE6A166),
    );
    c.save();
    c.clipPath(Path()..addOval(const Rect.fromLTWH(92, 100, 86, 86)));
    stroke(
      c,
      [const Offset(89, 143), const Offset(181, 143)],
      const Color(0xFF976349),
      2,
    );
    stroke(
      c,
      [const Offset(135, 100), const Offset(135, 186)],
      const Color(0xFF976349),
      2,
    );
    c.drawOval(
      const Rect.fromLTWH(110, 85, 47, 116),
      Paint()
        ..color = const Color(0xFF976349)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    c.restore();
  }

  void _spark(Canvas c, Offset p, double r) {
    stroke(c, [p - Offset(r, 0), p + Offset(r, 0)], const Color(0xFFB0A36C), 2);
    stroke(c, [p - Offset(0, r), p + Offset(0, r)], const Color(0xFFB0A36C), 2);
  }

  @override
  bool shouldRepaint(_ArtPainter oldDelegate) => oldDelegate.scene != scene;
}
