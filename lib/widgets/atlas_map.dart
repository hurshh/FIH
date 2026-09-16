import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models.dart';
import '../strings.dart';
import '../theme.dart';

class AtlasMap extends StatefulWidget {
  const AtlasMap({
    super.key,
    required this.data,
    required this.language,
    required this.selectedId,
    required this.onSelect,
    required this.onFind,
  });
  final AtlasData data;
  final AppLanguage language;
  final String? selectedId;
  final ValueChanged<Country> onSelect;
  final VoidCallback onFind;
  @override
  State<AtlasMap> createState() => _AtlasMapState();
}

class _AtlasMapState extends State<AtlasMap> {
  final transform = TransformationController();
  Size viewport = Size.zero;
  bool get zoomed => transform.value.getMaxScaleOnAxis() > 1.05;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    final current = transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 7.0);
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final point = transform.toScene(center);
    transform.value = Matrix4.identity()
      ..setEntry(0, 0, next)
      ..setEntry(1, 1, next)
      ..setEntry(0, 3, center.dx - point.dx * next)
      ..setEntry(1, 3, center.dy - point.dy * next);
    if (next == 1) transform.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.language);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: ocean,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.explore_outlined, color: forest, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      s.explore,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('find-country'),
                    tooltip: s.countries,
                    onPressed: widget.onFind,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  viewport = constraints.biggest;
                  final geometry = MapGeometry(viewport, widget.data.mapSize);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          key: const Key('interactive-map'),
                          transformationController: transform,
                          minScale: 1,
                          maxScale: 7,
                          boundaryMargin: const EdgeInsets.all(100),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              final point = geometry.toMap(
                                details.localPosition,
                              );
                              final country = widget.data.countryAt(point);
                              if (country != null) widget.onSelect(country);
                            },
                            child: CustomPaint(
                              size: viewport,
                              painter: AtlasPainter(
                                data: widget.data,
                                geometry: geometry,
                                language: widget.language,
                                selectedId: widget.selectedId,
                                onSelect: widget.onSelect,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 17,
                        bottom: 17,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cream.withValues(alpha: .92),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: forest,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  s.t(
                                    'Discoveries inside',
                                    'Hay descubrimientos',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: ink.withValues(alpha: .06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Flex(
                            direction: constraints.maxHeight < 230
                                ? Axis.horizontal
                                : Axis.vertical,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: const Key('zoom-in'),
                                tooltip: s.zoomIn,
                                onPressed: () => zoom(1.5),
                                icon: const Icon(Icons.add_rounded),
                              ),
                              IconButton(
                                key: const Key('zoom-out'),
                                tooltip: s.zoomOut,
                                onPressed: () => zoom(1 / 1.5),
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              IconButton(
                                key: const Key('reset-map'),
                                tooltip: s.reset,
                                onPressed: () =>
                                    transform.value = Matrix4.identity(),
                                icon: const Icon(
                                  Icons.center_focus_strong_rounded,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14, top: 4),
              child: Text(
                s.mapHint,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapGeometry {
  MapGeometry(this.viewport, this.mapSize);
  final Size viewport, mapSize;
  double get scale =>
      math.min(
        viewport.width / mapSize.width,
        viewport.height / mapSize.height,
      ) *
      .96;
  Offset get origin => Offset(
    (viewport.width - mapSize.width * scale) / 2,
    (viewport.height - mapSize.height * scale) / 2,
  );
  Offset toMap(Offset p) => (p - origin) / scale;
  Offset toScreen(Offset p) => origin + p * scale;
}

class AtlasPainter extends CustomPainter {
  AtlasPainter({
    required this.data,
    required this.geometry,
    required this.language,
    required this.selectedId,
    required this.onSelect,
  });
  final AtlasData data;
  final MapGeometry geometry;
  final AppLanguage language;
  final String? selectedId;
  final ValueChanged<Country> onSelect;

  void text(
    Canvas c,
    String value,
    Offset p,
    double size,
    Color color, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: bold ? .7 : 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(c, p - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  void paint(Canvas c, Size size) {
    final s = Strings(language);
    final grid = Paint()
      ..color = const Color(0xFFCADCD5).withValues(alpha: .45)
      ..strokeWidth = .6;
    for (var x = 20.0; x < size.width; x += 38) {
      for (var y = 10.0; y < size.height; y += 38) {
        c.drawCircle(Offset(x, y), .9, grid);
      }
    }
    c.save();
    c.translate(geometry.origin.dx, geometry.origin.dy);
    c.scale(geometry.scale);
    c.drawPath(data.context, Paint()..color = const Color(0xFFD5DFD5));
    for (final country in data.countries) {
      final selected = country.id == selectedId;
      c.drawPath(
        country.path.shift(const Offset(0, 3)),
        Paint()..color = const Color(0xFFB5CCBD),
      );
      c.drawPath(
        country.path,
        Paint()
          ..color = selected
              ? const Color(0xFF7BA78B)
              : countryColors[country.colorIndex],
      );
      c.drawPath(
        country.path,
        Paint()
          ..color = selected ? forest : const Color(0xFFFAF9EE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.4 : 1.4
          ..strokeJoin = StrokeJoin.round,
      );
    }
    // Masks are deliberately neutral and non-interactive, including on zoom.
    c.drawPath(data.deferred, Paint()..color = const Color(0xFFD5DFD5));
    text(
      c,
      s.t('PACIFIC', 'OCÉANO'),
      const Offset(254, 500),
      14,
      const Color(0xFF8AA79F),
    );
    text(
      c,
      s.t('OCEAN', 'PACÍFICO'),
      const Offset(254, 523),
      14,
      const Color(0xFF8AA79F),
    );
    text(
      c,
      s.t('ATLANTIC', 'OCÉANO'),
      const Offset(750, 338),
      14,
      const Color(0xFF8AA79F),
    );
    text(
      c,
      s.t('OCEAN', 'ATLÁNTICO'),
      const Offset(750, 361),
      14,
      const Color(0xFF8AA79F),
    );
    for (final country in data.countries) {
      if ([
        'CAN',
        'USA',
        'MEX',
        'BRA',
        'PER',
        'ARG',
        'COL',
      ].contains(country.id)) {
        final name = country.name.inLanguage(language);
        final p = country.label;
        text(
          c,
          name.toUpperCase(),
          p,
          (country.id == 'USA' ? 8.5 : 10) / geometry.scale,
          ink.withValues(alpha: .78),
          bold: true,
        );
      }
      if (data.factsFor(country.id).isNotEmpty) {
        final point = country.label + const Offset(0, 19);
        c.drawCircle(point, 7.5, Paint()..color = cream);
        c.drawCircle(point, 4, Paint()..color = forest);
      }
    }
    // Small, decorative compass rose.
    const p = Offset(119, 690);
    c.drawCircle(
      p,
      29,
      Paint()
        ..color = const Color(0xFFB3CCC0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - 21)
        ..lineTo(p.dx - 7, p.dy + 12)
        ..lineTo(p.dx, p.dy + 7)
        ..lineTo(p.dx + 7, p.dy + 12)
        ..close(),
      Paint()..color = const Color(0xFF87A896),
    );
    text(c, 'N', p + const Offset(0, -41), 12, const Color(0xFF87A896));
    c.restore();
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => data.countries.map((country) {
        final bounds = country.path.getBounds();
        return CustomPainterSemantics(
          rect: Rect.fromPoints(
            geometry.toScreen(bounds.topLeft),
            geometry.toScreen(bounds.bottomRight),
          ),
          properties: SemanticsProperties(
            label: country.name.inLanguage(language),
            button: true,
            selected: country.id == selectedId,
            textDirection: TextDirection.ltr,
            onTap: () => onSelect(country),
          ),
        );
      }).toList();

  @override
  bool shouldRepaint(AtlasPainter oldDelegate) =>
      oldDelegate.selectedId != selectedId ||
      oldDelegate.language != language ||
      oldDelegate.geometry.viewport != geometry.viewport;
  @override
  bool shouldRebuildSemantics(AtlasPainter oldDelegate) =>
      shouldRepaint(oldDelegate);
}
