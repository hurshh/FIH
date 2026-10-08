import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart';

enum AppLanguage { en, es }

class LocalText {
  const LocalText(this.en, this.es);
  factory LocalText.fromJson(Map<String, dynamic> json) =>
      LocalText(json['en'] as String, json['es'] as String);
  final String en;
  final String es;
  String inLanguage(AppLanguage language) =>
      language == AppLanguage.en ? en : es;
}

class Country {
  Country({
    required this.id,
    required this.name,
    required this.continent,
    required this.region,
    required this.colorIndex,
    required this.label,
    required this.path,
  });
  final String id;
  final LocalText name;
  final String continent;
  final String region;
  final int colorIndex;
  final Offset label;
  final Path path;
}

class DiscoveryFact {
  DiscoveryFact({
    required this.id,
    required this.countryId,
    required this.topic,
    required this.title,
    required this.body,
    required this.art,
    required this.sourceName,
    required this.sourceUrl,
  });
  factory DiscoveryFact.fromJson(Map<String, dynamic> json) => DiscoveryFact(
    id: json['id'] as String,
    countryId: json['country'] as String,
    topic: json['topic'] as String,
    title: LocalText.fromJson(json['title']),
    body: LocalText.fromJson(json['body']),
    art: json['art'] as String,
    sourceName: json['sourceName'] as String,
    sourceUrl: json['sourceUrl'] as String,
  );
  final String id, countryId, topic, art, sourceName, sourceUrl;
  final LocalText title, body;
}

Path parsePolygons(List<dynamic> polygons) {
  final path = Path()..fillType = PathFillType.evenOdd;
  for (final polygon in polygons) {
    for (final ring in polygon as List<dynamic>) {
      final points = (ring as List<dynamic>)
          .map(
            (p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          )
          .toList();
      path.addPolygon(points, true);
    }
  }
  return path;
}

/// One continent's map: selectable countries plus non-interactive layers.
class AtlasContinent {
  AtlasContinent({
    required this.id,
    required this.countries,
    required this.context,
    required this.deferred,
    required this.mapSize,
  });
  final String id;
  final List<Country> countries;
  final Path context, deferred;
  final Size mapSize;

  factory AtlasContinent.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final deferred = Path();
    for (final item in json['deferred']) {
      deferred.addPath(parsePolygons(item['polygons']), Offset.zero);
    }
    final context = Path();
    for (final item in json['context']) {
      context.addPath(parsePolygons(item['polygons']), Offset.zero);
    }
    final countries = (json['countries'] as List<dynamic>).map((item) {
      final original = parsePolygons(item['polygons']);
      return Country(
        id: item['id'],
        name: LocalText(item['en'], item['es']),
        continent: id,
        region: item['region'],
        colorIndex: item['color'],
        label: Offset(
          (item['label'][0] as num).toDouble(),
          (item['label'][1] as num).toDouble(),
        ),
        path: Path.combine(PathOperation.difference, original, deferred),
      );
    }).toList();
    return AtlasContinent(
      id: id,
      countries: countries,
      context: context,
      deferred: deferred,
      mapSize: Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
    );
  }

  Country? countryAt(Offset point) {
    if (deferred.contains(point)) return null;
    for (final country in countries.reversed) {
      if (country.path.contains(point)) return country;
    }
    return null;
  }
}

class AtlasData {
  AtlasData({required this.continents, required this.facts});
  final List<AtlasContinent> continents;
  final List<DiscoveryFact> facts;

  List<Country> get countries => [for (final c in continents) ...c.countries];

  AtlasContinent continent(String id) =>
      continents.firstWhere((c) => c.id == id);

  static Future<AtlasData> load() async {
    final files = await Future.wait([
      rootBundle.loadString('assets/data/map.json'),
      rootBundle.loadString('assets/data/facts.json'),
    ]);
    final map = jsonDecode(files[0]) as Map<String, dynamic>;
    return AtlasData(
      continents: (map['continents'] as List<dynamic>)
          .map((item) => AtlasContinent.fromJson(item))
          .toList(),
      facts: (jsonDecode(files[1]) as List<dynamic>)
          .map((item) => DiscoveryFact.fromJson(item))
          .toList(),
    );
  }

  List<DiscoveryFact> factsFor(String id) =>
      facts.where((f) => f.countryId == id).toList();
}

/// A separate shuffle bag per country. Translations never participate in draws.
class FactBag {
  FactBag({Random? random}) : _random = random ?? Random();
  final Random _random;
  final Map<String, List<DiscoveryFact>> _bags = {};
  final Map<String, DiscoveryFact> _last = {};

  DiscoveryFact? current(String countryId) => _last[countryId];

  DiscoveryFact? draw(String countryId, List<DiscoveryFact> facts) {
    if (facts.isEmpty) return null;
    assert(facts.every((fact) => fact.countryId == countryId));
    var bag = _bags[countryId];
    if (bag == null || bag.isEmpty) {
      bag = [...facts]..shuffle(_random);
      if (bag.length > 1 && bag.last.id == _last[countryId]?.id) {
        final first = bag.first;
        bag[0] = bag.last;
        bag[bag.length - 1] = first;
      }
      _bags[countryId] = bag;
    }
    return _last[countryId] = bag.removeLast();
  }
}
