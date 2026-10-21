import 'dart:convert';

import 'package:flutter/material.dart';

import 'models.dart';
import 'strings.dart';

/// Everything the app reads aloud, split into short parts. The app speaks
/// these parts one after another; `tool/export_speech.dart` lists every part
/// so recorded clips can be generated ahead of time. Keeping both in one place
/// means a recording always matches what is on screen.

typedef QuickInfo = ({
  IconData icon,
  String headline,
  String? unit,
  List<String> lines,
  String source,
});

QuickInfo quickInfo(
  AtlasData data,
  Country country,
  QuickKind kind,
  Strings s,
) {
  final profile = data.profiles[country.id]!;
  final name = country.name.inLanguage(s.language);
  final total = data.profiles.length;
  return switch (kind) {
    QuickKind.people => (
      icon: Icons.groups_rounded,
      headline: s.amount(profile.population),
      unit: s.people.toLowerCase(),
      lines: [
        s.populationSentence(name, s.amount(profile.population)),
        s.populationRank(data.rank(country.id, (p) => p.population), total),
      ],
      source: s.source(s.worldBank, profile.populationYear),
    ),
    QuickKind.size => (
      icon: Icons.square_foot_rounded,
      headline: s.amount(profile.area),
      unit: s.areaUnit,
      lines: [
        s.areaSentence(name, s.amount(profile.area)),
        s.areaRank(data.rank(country.id, (p) => p.area), total),
      ],
      source: s.source(s.worldBank, profile.areaYear),
    ),
    QuickKind.capital => (
      icon: Icons.account_balance_outlined,
      headline: capitalsOf(profile).inLanguage(s.language),
      unit: null,
      lines: [
        s.capitalSentence(
          name,
          profile.capitals.map((c) => c.inLanguage(s.language)).toList(),
        ),
      ],
      source: s.source(s.naturalEarth),
    ),
    QuickKind.neighbours => (
      icon: Icons.share_location_rounded,
      headline: '${profile.neighbours.length}',
      unit: s.t('land neighbors', 'vecinos terrestres'),
      lines: [s.neighbourSentence(name, profile.neighbours.length)],
      source: s.source(s.naturalEarth),
    ),
  };
}

LocalText capitalsOf(CountryProfile profile) => LocalText(
  profile.capitals.map((c) => c.en).join(' & '),
  profile.capitals.map((c) => c.es).join(' y '),
);

List<String> welcomeSpeech(Strings s) => [
  ...s.welcomeTitle.split('\n'),
  s.welcomeBody,
];

List<String> cardSpeech(
  AtlasData data,
  Country country,
  DiscoveryCard? card,
  Strings s,
) {
  final name = country.name.inLanguage(s.language);
  return switch (card) {
    DiscoveryFact fact => [
      name,
      fact.title.inLanguage(s.language),
      fact.body.inLanguage(s.language),
    ],
    QuickFact(:final kind) => [
      name,
      ...quickInfo(data, country, kind, s).lines,
      if (kind == QuickKind.neighbours &&
          data.profiles[country.id]!.neighbours.isNotEmpty)
        _neighbourList(data.profiles[country.id]!, s),
    ],
    _ => [name, s.preview, s.previewBody],
  };
}

String _neighbourList(CountryProfile profile, Strings s) =>
    '${profile.neighbours.map((n) => n.name.inLanguage(s.language)).join(', ')}.';

List<String> questionSpeech(QuizQuestion q, bool answerFirst, Strings s) {
  final (first, second) = answerFirst
      ? (q.answer, q.wrong)
      : (q.wrong, q.answer);
  return [
    q.question.inLanguage(s.language),
    first.inLanguage(s.language),
    _orOption(second.inLanguage(s.language), s),
  ];
}

String _orOption(String option, Strings s) => '${s.or} $option?';

List<String> feedbackSpeech(bool correct, LocalText answer, Strings s) =>
    correct ? [s.correct] : [s.notQuiteIntro, answer.inLanguage(s.language)];

List<String> scoreSpeech(String country, int score, int total, Strings s) => [
  s.scoreLine(score, total),
  s.scoreMessage(country, score, total),
];

/// Every part [welcomeSpeech], [cardSpeech], and the test can produce.
Set<String> allSpeech(AtlasData data, Strings s) {
  final parts = <String>{...welcomeSpeech(s), s.correct, s.notQuiteIntro};
  final options = <String>{s.onlySea, s.yesItDoes};
  final testLengths = <int>{};
  for (final country in data.countries) {
    final name = country.name.inLanguage(s.language);
    final profile = data.profiles[country.id];
    for (final card in data.cardsFor(country.id)) {
      parts.addAll(cardSpeech(data, country, card, s));
    }
    parts.addAll(cardSpeech(data, country, null, s));
    for (final fact in data.factsFor(country.id)) {
      final quiz = fact.quiz;
      if (quiz == null) continue;
      parts.add(quiz.question.inLanguage(s.language));
      options
        ..add(quiz.answer.inLanguage(s.language))
        ..add(quiz.wrong.inLanguage(s.language));
    }
    options.add(name);
    if (profile == null) continue;
    final total = data.factsFor(country.id).length + 4;
    testLengths.add(total);
    parts.addAll([
      s.quizCapital(name),
      s.quizMorePeople,
      s.quizBigger,
      profile.neighbours.isEmpty
          ? s.quizAnyNeighbours(name)
          : s.quizNeighbour(name),
      s.scoreMessage(name, total, total),
      s.scoreMessage(name, total - 1, total),
      s.scoreMessage(name, 0, total),
    ]);
    options
      ..add(capitalsOf(profile).inLanguage(s.language))
      ..addAll(profile.neighbours.map((n) => n.name.inLanguage(s.language)));
  }
  for (final option in options) {
    parts
      ..add(option)
      ..add(_orOption(option, s));
  }
  for (final total in testLengths) {
    for (var score = 0; score <= total; score++) {
      parts.add(s.scoreLine(score, total));
    }
  }
  return parts;
}

/// Makes written numbers and symbols read naturally: "3 290 000" and
/// "530,000" are said as whole numbers, and "&" as "and"/"y".
String forSpeech(String text, AppLanguage language) => text
    .replaceAll(RegExp(r'(?<=\d)[ ,](?=\d{3}(?!\d))'), '')
    .replaceAll(' & ', language == AppLanguage.en ? ' and ' : ' y ')
    .replaceAll(' · ', ', ')
    .replaceAll('\n', ' ');

/// Stable file name for a recorded clip of [text]: language plus a 64-bit
/// FNV-1a hash of the spoken words (computed in 32-bit halves so it matches
/// on every platform, including the web).
String speechKey(AppLanguage language, String text) {
  final bytes = utf8.encode(forSpeech(text, language));
  String fnv(int seed) {
    var h = seed;
    for (final b in bytes) {
      h ^= b;
      // h * 16777619, where 16777619 = 2^24 + 403, kept to 32 bits.
      h = (h * 403 + ((h << 24) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  return '${language.name}_${fnv(0x811C9DC5)}${fnv(0x050C5D1F)}';
}
