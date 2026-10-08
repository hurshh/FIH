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

/// Anything shown by "Another fact": a fun fact or a quick fact.
abstract interface class DiscoveryCard {
  String get id;
  String get countryId;
}

enum QuickKind { people, size, capital, neighbours }

/// A card generated from the country's [CountryProfile].
class QuickFact implements DiscoveryCard {
  const QuickFact(this.countryId, this.kind);
  @override
  final String countryId;
  final QuickKind kind;
  @override
  String get id => '$countryId-${kind.name}';
}

class DiscoveryFact implements DiscoveryCard {
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
  @override
  final String id, countryId;
  final String topic, art, sourceName, sourceUrl;
  final LocalText title, body;
}

/// Structured quick facts shown alongside the random fact collection.
class CountryProfile {
  CountryProfile({
    required this.population,
    required this.populationYear,
    required this.area,
    required this.areaYear,
    required this.capitals,
    required this.neighbours,
  });
  factory CountryProfile.fromJson(Map<String, dynamic> json) => CountryProfile(
    population: json['population']['value'] as int,
    populationYear: json['population']['year'] as int,
    area: (json['area']['value'] as num).toDouble(),
    areaYear: json['area']['year'] as int,
    capitals: (json['capitals'] as List<dynamic>)
        .map((item) => LocalText.fromJson(item))
        .toList(),
    neighbours: (json['neighbours'] as List<dynamic>)
        .map(
          (item) => (id: item['id'] as String, name: LocalText.fromJson(item)),
        )
        .toList(),
  );
  final int population, populationYear, areaYear;
  final double area;
  final List<LocalText> capitals;
  final List<({String id, LocalText name})> neighbours;
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
    // Areas drawn as part of one country and removed from any other outline.
    final transfers = <String, Path>{};
    var transferred = Path();
    for (final item in json['transfers'] ?? const []) {
      final area = parsePolygons(item['polygons']);
      transfers[item['to']] = transfers.containsKey(item['to'])
          ? Path.combine(PathOperation.union, transfers[item['to']]!, area)
          : area;
      transferred = Path.combine(PathOperation.union, transferred, area);
    }
    final countries = (json['countries'] as List<dynamic>).map((item) {
      var path = Path.combine(
        PathOperation.difference,
        parsePolygons(item['polygons']),
        deferred,
      );
      final gained = transfers[item['id']];
      if (gained != null) {
        path = Path.combine(PathOperation.union, path, gained);
      } else if (path.getBounds().overlaps(transferred.getBounds())) {
        path = Path.combine(PathOperation.difference, path, transferred);
      }
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
        path: path,
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
  AtlasData({
    required this.continents,
    required this.facts,
    this.profiles = const {},
  });
  final List<AtlasContinent> continents;
  final List<DiscoveryFact> facts;
  final Map<String, CountryProfile> profiles;

  List<Country> get countries => [for (final c in continents) ...c.countries];

  AtlasContinent continent(String id) =>
      continents.firstWhere((c) => c.id == id);

  static Future<AtlasData> load() async {
    final files = await Future.wait([
      rootBundle.loadString('assets/data/map.json'),
      rootBundle.loadString('assets/data/facts.json'),
      rootBundle.loadString('assets/data/profiles.json'),
    ]);
    final map = jsonDecode(files[0]) as Map<String, dynamic>;
    return AtlasData(
      continents: (map['continents'] as List<dynamic>)
          .map((item) => AtlasContinent.fromJson(item))
          .toList(),
      facts: (jsonDecode(files[1]) as List<dynamic>)
          .map((item) => DiscoveryFact.fromJson(item))
          .toList(),
      profiles: {
        for (final MapEntry(:key, :value)
            in (jsonDecode(files[2])['countries'] as Map<String, dynamic>)
                .entries)
          key: CountryProfile.fromJson(value),
      },
    );
  }

  List<DiscoveryFact> factsFor(String id) =>
      facts.where((f) => f.countryId == id).toList();

  /// Every card "Another fact" cycles through: fun facts, then quick facts.
  List<DiscoveryCard> cardsFor(String id) => [
    ...factsFor(id),
    if (profiles.containsKey(id))
      for (final kind in QuickKind.values) QuickFact(id, kind),
  ];

  /// 1-based position among all countries in the atlas, largest first.
  int rank(String id, num Function(CountryProfile) measure) =>
      1 +
      profiles.values.where((p) => measure(p) > measure(profiles[id]!)).length;
}

/// A separate shuffle bag per country. Translations never participate in draws.
class FactBag {
  FactBag({Random? random}) : _random = random ?? Random();
  final Random _random;
  final Map<String, List<DiscoveryCard>> _bags = {};
  final Map<String, DiscoveryCard> _last = {};

  DiscoveryCard? current(String countryId) => _last[countryId];

  DiscoveryCard? draw(String countryId, List<DiscoveryCard> facts) {
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
