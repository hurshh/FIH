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
    required this.continent,
    required this.language,
    required this.selectedId,
    required this.onSelect,
    required this.onContinent,
    required this.onFind,
  });
  final AtlasData data;
  final AtlasContinent continent;
  final AppLanguage language;
  final String? selectedId;
  final ValueChanged<Country> onSelect;
  final ValueChanged<String> onContinent;
  final VoidCallback onFind;
  @override
  State<AtlasMap> createState() => _AtlasMapState();
}

class _AtlasMapState extends State<AtlasMap> {
  // Each continent keeps its own pan and zoom while the other is shown.
  final transforms = <String, TransformationController>{};
  TransformationController get transform =>
      transforms.putIfAbsent(widget.continent.id, TransformationController.new);
  Size viewport = Size.zero;
  @override
  void dispose() {
    for (final transform in transforms.values) {
      transform.dispose();
    }
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

  Widget _continentSwitch(Strings s) => Semantics(
    label: s.explore,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: cream.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.data.continents.map((continent) {
          final active = continent.id == widget.continent.id;
          return Padding(
            padding: const EdgeInsets.all(3),
            child: Semantics(
              selected: active,
              child: TextButton(
                key: Key('continent-${continent.id}'),
                onPressed: () => widget.onContinent(continent.id),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: active ? Colors.white : Colors.transparent,
                  foregroundColor: active ? forest : muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: Text(
                  s.continent(continent.id),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

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
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _continentSwitch(s),
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
                  final geometry = MapGeometry(
                    viewport,
                    widget.continent.mapSize,
                  );
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
                              final country = widget.continent.countryAt(point);
                              if (country != null) widget.onSelect(country);
                            },
                            child: CustomPaint(
                              size: viewport,
                              painter: AtlasPainter(
                                data: widget.data,
                                continent: widget.continent,
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

/// Hand-placed decoration for each continent, in map units.
class MapStyle {
  const MapStyle({
    required this.oceans,
    required this.labelled,
    required this.compass,
    this.smallLabels = const {},
    this.fadeEdges = false,
  });
  final List<({List<String> en, List<String> es, Offset at})> oceans;
  final Set<String> labelled, smallLabels;
  final Offset compass;
  // Neighbouring land is clipped to the map window, so soften the cut edges.
  final bool fadeEdges;
  static const byContinent = {
    'americas': MapStyle(
      oceans: [
        (
          en: ['PACIFIC', 'OCEAN'],
          es: ['OCÉANO', 'PACÍFICO'],
          at: Offset(254, 500),
        ),
        (
          en: ['ATLANTIC', 'OCEAN'],
          es: ['OCÉANO', 'ATLÁNTICO'],
          at: Offset(750, 338),
        ),
      ],
      labelled: {'CAN', 'USA', 'MEX', 'BRA', 'PER', 'ARG', 'COL'},
      smallLabels: {'USA'},
      compass: Offset(119, 690),
    ),
    'asia': MapStyle(
      oceans: [
        (
          en: ['INDIAN', 'OCEAN'],
          es: ['OCÉANO', 'ÍNDICO'],
          at: Offset(396, 384),
        ),
        (
          en: ['PACIFIC', 'OCEAN'],
          es: ['OCÉANO', 'PACÍFICO'],
          at: Offset(696, 264),
        ),
      ],
      labelled: {'CHN', 'IND', 'KAZ', 'MNG', 'SAU', 'IRN', 'IDN', 'TUR', 'JPN'},
      compass: Offset(168, 408),
      fadeEdges: true,
    ),
  };
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
    required this.continent,
    required this.geometry,
    required this.language,
    required this.selectedId,
    required this.onSelect,
  });
  final AtlasData data;
  final AtlasContinent continent;
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
    final style = MapStyle.byContinent[continent.id]!;
    if (style.fadeEdges) {
      final bounds = Offset.zero & continent.mapSize;
      c.saveLayer(bounds, Paint());
      c.drawPath(continent.context, Paint()..color = const Color(0xFFD5DFD5));
      const fade = 40.0;
      void edge(Rect r, Alignment from) => c.drawRect(
        r,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = LinearGradient(
            begin: from,
            end: -from,
            colors: const [Color(0xFF000000), Color(0x00000000)],
          ).createShader(r),
      );
      final w = bounds.width, h = bounds.height;
      edge(Rect.fromLTWH(0, 0, fade, h), Alignment.centerLeft);
      edge(Rect.fromLTWH(w - fade, 0, fade, h), Alignment.centerRight);
      edge(Rect.fromLTWH(0, 0, w, fade), Alignment.topCenter);
      edge(Rect.fromLTWH(0, h - fade, w, fade), Alignment.bottomCenter);
      c.restore();
    } else {
      c.drawPath(continent.context, Paint()..color = const Color(0xFFD5DFD5));
    }
    for (final country in continent.countries) {
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
    c.drawPath(continent.deferred, Paint()..color = const Color(0xFFD5DFD5));
    for (final ocean in style.oceans) {
      final lines = language == AppLanguage.en ? ocean.en : ocean.es;
      for (var i = 0; i < lines.length; i++) {
        text(
          c,
          lines[i],
          ocean.at + Offset(0, 23.0 * i),
          14,
          const Color(0xFF8AA79F),
        );
      }
    }
    for (final country in continent.countries) {
      final labelled = style.labelled.contains(country.id);
      if (labelled) {
        final name = country.name.inLanguage(language);
        final p = country.label;
        text(
          c,
          name.toUpperCase(),
          p,
          (style.smallLabels.contains(country.id) ? 8.5 : 10) / geometry.scale,
          ink.withValues(alpha: .78),
          bold: true,
        );
      }
      if (data.factsFor(country.id).isNotEmpty) {
        final point = country.label + Offset(0, labelled ? 19 : 0);
        c.drawCircle(point, 7.5, Paint()..color = cream);
        c.drawCircle(point, 4, Paint()..color = forest);
      }
    }
    // Small, decorative compass rose.
    final p = style.compass;
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
      (size) => continent.countries.map((country) {
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
      oldDelegate.continent != continent ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.language != language ||
      oldDelegate.geometry.viewport != geometry.viewport;
  @override
  bool shouldRebuildSemantics(AtlasPainter oldDelegate) =>
      shouldRepaint(oldDelegate);
}
