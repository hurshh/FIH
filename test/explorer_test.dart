import 'dart:async';
import 'dart:math';

import 'package:americas_explorer/app.dart';
import 'package:americas_explorer/models.dart';
import 'package:americas_explorer/narrator.dart';
import 'package:americas_explorer/quiz.dart';
import 'package:americas_explorer/speech_script.dart';
import 'package:americas_explorer/strings.dart';
import 'package:americas_explorer/widgets/atlas_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what would be spoken. Each part "plays" until [finish] or [stop].
class FakeSpeaker implements Speaker {
  final spoken = <(String, AppLanguage, String?)>[];
  int stops = 0;
  Completer<void>? _part;
  @override
  Future<void> say(String text, AppLanguage language, {String? clip}) {
    spoken.add((text, language, clip));
    return (_part = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    finish();
  }

  void finish() {
    final part = _part;
    _part = null;
    if (part != null && !part.isCompleted) part.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  late AtlasData data;
  late Set<String> clips;
  setUpAll(() async {
    data = await AtlasData.load();
    clips = await loadClipIndex();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final name in ['Nunito', 'Fraunces']) {
      await (FontLoader(
        name,
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
  });

  Future<void> boot(
    WidgetTester tester, {
    Size size = const Size(1200, 900),
    AppLanguage language = AppLanguage.en,
    double textScale = 1,
    Future<void> Function(AppLanguage)? persist,
    AtlasData? atlas,
    Speaker? speaker,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture'),
        child: AtlasApp(
          data: atlas ?? data,
          initialLanguage: language,
          random: Random(7),
          persistLanguage: persist,
          speaker: speaker ?? FakeSpeaker(),
          clips: Future.value(clips),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String id, String query) async {
    await tester.tap(find.byKey(const Key('find-country')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search')), query);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('pick-$id')));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(Key(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  // "Another fact" never repeats within a cycle, so every card appears in time.
  Future<void> showCard(WidgetTester tester, String key) async {
    for (var i = 0; i < 10 && find.byKey(Key(key)).evaluate().isEmpty; i++) {
      await tapKey(tester, 'another-fact');
    }
    expect(find.byKey(Key(key)), findsOneWidget);
  }

  String visibleFactId(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.key)
      .whereType<ValueKey<String>>()
      .firstWhere((key) => key.value.startsWith('body-'))
      .value;

  test('bundled data covers the Americas and all demonstration topics', () {
    final americas = data.continent('americas');
    expect(americas.countries.length, 35);
    expect(americas.countries.map((c) => c.id).toSet().length, 35);
    expect(data.facts.map((f) => f.topic).toSet().length, 6);
    expect(data.facts.map((f) => f.id).toSet().length, data.facts.length);
    for (final fact in data.facts) {
      expect(data.countries.any((c) => c.id == fact.countryId), isTrue);
      expect(fact.body.en, isNotEmpty);
      expect(fact.body.es, isNotEmpty);
      expect(Uri.parse(fact.sourceUrl).hasScheme, isTrue);
    }
    expect(data.countries.any((c) => c.id == 'FLK'), isFalse);
    // The source's Esequiba mask is non-interactive even inside a country outline.
    final point = Offset((-59.5 + 170) * 6, (84 - 6.5) * 6);
    expect(americas.deferred.contains(point), isTrue);
    expect(americas.countryAt(point), isNull);
  });

  test('bundled data covers Asia with deferred disputed areas', () {
    final asia = data.continent('asia');
    Offset at(double lon, double lat) => Offset((lon - 22) * 6, (62 - lat) * 6);
    expect(asia.countries.length, 47);
    expect(data.countries.map((c) => c.id).toSet().length, 35 + 47);
    for (final id in ['CHN', 'IND', 'JPN', 'IDN', 'SAU', 'TUR', 'MDV']) {
      expect(asia.countries.any((c) => c.id == id), isTrue, reason: id);
    }
    for (final id in ['TWN', 'PSX', 'CYN', 'HKG', 'MAC']) {
      expect(data.countries.any((c) => c.id == id), isFalse, reason: id);
    }
    expect(asia.countryAt(at(78.9, 22.5))?.id, 'IND');
    expect(asia.countryAt(at(138.5, 36.2))?.id, 'JPN');
    expect(asia.countryAt(at(34.9, 31.5))?.id, 'ISR');
    // Jammu and Kashmir is part of India, including Pakistan- and
    // China-administered areas; neither neighbour's outline overlaps it.
    for (final (lon, lat) in [
      (75.3, 34.1),
      (73.8, 34.4),
      (74.5, 36.0),
      (79.5, 35.2),
    ]) {
      expect(asia.countryAt(at(lon, lat))?.id, 'IND', reason: '$lon,$lat');
    }
    final pakistan = asia.countries.firstWhere((c) => c.id == 'PAK').path;
    final china = asia.countries.firstWhere((c) => c.id == 'CHN').path;
    expect(pakistan.contains(at(74.5, 36.0)), isFalse);
    expect(china.contains(at(79.5, 35.2)), isFalse);
    expect(asia.countryAt(at(69, 30))?.id, 'PAK');
    // Taiwan stays neutral and non-interactive.
    expect(asia.countryAt(at(121, 23.7)), isNull);
    expect(
      data.facts.where((f) => asia.countries.any((c) => c.id == f.countryId)),
      isNotEmpty,
    );
  });

  test('quick facts cover every country and follow the map', () {
    expect(data.profiles.keys.toSet(), data.countries.map((c) => c.id).toSet());
    for (final profile in data.profiles.values) {
      expect(profile.population, greaterThan(0));
      expect(profile.area, greaterThan(0));
      expect(profile.capitals, isNotEmpty);
    }
    Set<String> neighbours(String id) =>
        data.profiles[id]!.neighbours.map((n) => n.id).toSet();
    expect(neighbours('IND'), containsAll(['AFG', 'PAK', 'CHN', 'NPL']));
    expect(neighbours('IND'), isNot(contains('KAS')));
    expect(neighbours('PAK'), isNot(contains('CHN')));
    expect(neighbours('USA'), {'CAN', 'MEX'});
    expect(neighbours('JPN'), isEmpty);
    expect(
      data.rank('CHN', (p) => p.area),
      lessThan(data.rank('IND', (p) => p.area)),
    );
    expect(data.rank('IND', (p) => p.population), 1);
  });

  test('quick fact numbers read naturally in both languages', () {
    const en = Strings(AppLanguage.en), es = Strings(AppLanguage.es);
    expect(en.amount(1463865525), '1.46 billion');
    expect(es.amount(1463865525), '1460 millones');
    expect(en.amount(341784857), '342 million');
    expect(es.amount(341784857), '342 millones');
    expect(en.amount(3287260), '3.29 million');
    expect(es.amount(3287260), '3 290 000');
    expect(en.amount(529676), '530,000');
    expect(es.amount(529676), '530 000');
    expect(en.amount(750), '750');
    expect(
      es.populationSentence('India', es.amount(1463865525)),
      'En India viven unas 1460 millones de personas.',
    );
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22].map(en.ordinal), [
      '1st',
      '2nd',
      '3rd',
      '4th',
      '11th',
      '12th',
      '13th',
      '21st',
      '22nd',
    ]);
  });

  test('every country gets a sound two-option test', () {
    for (final (i, country) in data.countries.indexed) {
      final questions = buildQuiz(data, country, Random(i));
      expect(
        questions.length,
        data.factsFor(country.id).length + 4,
        reason: country.id,
      );
      for (final q in questions) {
        expect(q.answer.en, isNot(q.wrong.en), reason: q.question.en);
        expect(q.answer.es, isNot(q.wrong.es), reason: q.question.es);
        expect(
          [
            q.question,
            q.answer,
            q.wrong,
          ].every((t) => t.en.isNotEmpty && t.es.isNotEmpty),
          isTrue,
        );
      }
      final byName = {for (final c in data.countries) c.name.en: c.id};
      for (final (question, measure) in [
        ('Which country has more people?', (CountryProfile p) => p.population),
        ('Which country is bigger?', (CountryProfile p) => p.area),
      ]) {
        final q = questions.firstWhere((q) => q.question.en == question);
        expect(
          measure(data.profiles[byName[q.answer.en]]!),
          greaterThan(measure(data.profiles[byName[q.wrong.en]]!)),
          reason: '${country.id}: $question',
        );
      }
      final neighbours = data.profiles[country.id]!.neighbours
          .map((n) => n.name.en)
          .toSet();
      if (neighbours.isNotEmpty) {
        final q = questions.firstWhere(
          (q) => q.question.en.startsWith('Which country shares'),
        );
        expect(neighbours, contains(q.answer.en));
        expect(neighbours, isNot(contains(q.wrong.en)));
      }
    }
    for (final fact in data.facts) {
      expect(fact.quiz, isNotNull, reason: fact.id);
    }
  });

  testWidgets('map hit testing selects a country, including after zoom', (
    tester,
  ) async {
    await boot(tester);
    final painterFinder = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is AtlasPainter,
    );
    final painter =
        (tester.widget<CustomPaint>(painterFinder).painter! as AtlasPainter);
    final brazil = data.countries.firstWhere((c) => c.id == 'BRA');
    final origin = tester.getTopLeft(painterFinder);
    await tester.tapAt(origin + painter.geometry.toScreen(brazil.label));
    await tester.pumpAndSettle();
    expect(find.text('Brazil'), findsOneWidget);
    await tester.tap(find.byKey(const Key('zoom-in')));
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('interactive-map')),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1.5, .01),
    );
    final usa = data.countries.firstWhere((country) => country.id == 'USA');
    final transformed = MatrixUtils.transformPoint(
      viewer.transformationController!.value,
      painter.geometry.toScreen(usa.label),
    );
    await tester.tapAt(origin + transformed);
    await tester.pumpAndSettle();
    expect(find.text('United States'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset-map')));
    await tester.pumpAndSettle();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'language switch preserves fact and persists the selected language',
    (tester) async {
      final saved = <AppLanguage>[];
      await boot(tester, persist: (language) async => saved.add(language));
      await pick(tester, 'MEX', 'mexico');
      final before = visibleFactId(tester);
      await tester.tap(find.byKey(const Key('language-es')));
      await tester.pumpAndSettle();
      expect(visibleFactId(tester), before);
      expect(find.text('México'), findsOneWidget);
      expect(saved, [AppLanguage.es]);
      final button = find.byKey(const Key('another-fact'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(visibleFactId(tester), isNot(before));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'phone preview and back preserve map zoom; search handles accents',
    (tester) async {
      await boot(tester, size: const Size(390, 844), language: AppLanguage.es);
      await tester.tap(find.byKey(const Key('zoom-in')));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<InteractiveViewer>(find.byKey(const Key('interactive-map')))
          .transformationController!;
      // Countries without fun facts still cycle through their quick facts.
      await pick(tester, 'CAN', 'canada');
      expect(find.text('Pronto habrá más sorpresas'), findsNothing);
      expect(find.byKey(const Key('another-fact')), findsOneWidget);
      await tester.tap(find.byKey(const Key('back-to-map')));
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), closeTo(1.5, .01));
      await pick(tester, 'PER', 'peru');
      expect(find.text('Perú'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('single-fact country and empty search have usable states', (
    tester,
  ) async {
    // Every bundled country has several facts, so keep one for this state.
    final single = AtlasData(
      continents: data.continents,
      facts: data.facts
          .where((f) => f.countryId != 'USA' || f.id == 'usa-basketball')
          .toList(),
    );
    await boot(tester, atlas: single);
    await pick(tester, 'USA', 'United States');
    expect(find.byKey(const Key('another-fact')), findsNothing);
    expect(
      find.textContaining('You found our first fact here'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('find-country')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search')), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No places found. Try another name.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone supports larger Spanish text without overflow', (
    tester,
  ) async {
    await boot(
      tester,
      size: const Size(375, 812),
      language: AppLanguage.es,
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    await pick(tester, 'USA', 'estados');
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 6; i++) {
      await tapKey(tester, 'another-fact');
      expect(tester.takeException(), isNull, reason: visibleFactId(tester));
    }
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet landing visual', (tester) async {
    await boot(tester, size: const Size(1280, 960));
    await expectLater(
      find.byKey(const Key('capture')),
      matchesGoldenFile('goldens/tablet-map.png'),
    );
  });

  testWidgets('tablet Asia visual', (tester) async {
    await boot(tester, size: const Size(1280, 960));
    await tester.tap(find.byKey(const Key('continent-asia')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('capture')),
      matchesGoldenFile('goldens/tablet-asia.png'),
    );
  });

  testWidgets('landscape search remains usable above the keyboard', (
    tester,
  ) async {
    await boot(tester, size: const Size(844, 390), language: AppLanguage.es);
    await tester.tap(find.byKey(const Key('find-country')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('country-search')), 'peru');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('pick-PER')));
    await tester.pumpAndSettle();
    expect(find.text('Perú'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone landscape keeps map and controls usable', (tester) async {
    await boot(tester, size: const Size(844, 390), language: AppLanguage.es);
    expect(
      tester.getSize(find.byKey(const Key('interactive-map'))).height,
      greaterThan(120),
    );
    await tester.tap(find.byKey(const Key('zoom-in')));
    await tester.pumpAndSettle();
    await pick(tester, 'MEX', 'mexico');
    expect(find.text('México'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinch zoom and pan do not select countries accidentally', (
    tester,
  ) async {
    await boot(tester);
    final map = find.byKey(const Key('interactive-map'));
    final center = tester.getCenter(map);
    final one = await tester.startGesture(
      center - const Offset(45, 0),
      pointer: 1,
    );
    final two = await tester.startGesture(
      center + const Offset(45, 0),
      pointer: 2,
    );
    await tester.pump();
    await one.moveTo(center - const Offset(100, 0));
    await two.moveTo(center + const Offset(100, 0));
    await tester.pump();
    await one.up();
    await two.up();
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(map)
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    expect(find.byKey(const Key('country-name')), findsNothing);
    final before = controller.value.clone();
    await tester.drag(map, const Offset(35, 25));
    await tester.pumpAndSettle();
    expect(controller.value, isNot(before));
    expect(find.byKey(const Key('country-name')), findsNothing);
  });

  testWidgets('continent switch keeps zoom and search jumps continents', (
    tester,
  ) async {
    await boot(tester);
    TransformationController controller() => tester
        .widget<InteractiveViewer>(find.byKey(const Key('interactive-map')))
        .transformationController!;
    AtlasPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is AtlasPainter,
                  ),
                )
                .painter!
            as AtlasPainter;
    await tester.tap(find.byKey(const Key('zoom-in')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continent-asia')));
    await tester.pumpAndSettle();
    expect(painter().continent.id, 'asia');
    expect(controller().value.getMaxScaleOnAxis(), 1);
    final origin = tester.getTopLeft(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is AtlasPainter,
      ),
    );
    final india = data.countries.firstWhere((c) => c.id == 'IND');
    await tester.tapAt(origin + painter().geometry.toScreen(india.label));
    await tester.pumpAndSettle();
    expect(find.text('India'), findsOneWidget);
    expect(find.text('South Asia'), findsOneWidget);
    await pick(tester, 'MEX', 'mexico');
    expect(painter().continent.id, 'americas');
    expect(controller().value.getMaxScaleOnAxis(), closeTo(1.5, .01));
    await pick(tester, 'JPN', 'japon');
    expect(painter().continent.id, 'asia');
    expect(find.text('Japan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick facts appear among facts and neighbours are visitable', (
    tester,
  ) async {
    await boot(tester);
    await pick(tester, 'IND', 'india');
    await showCard(tester, 'quick-people');
    expect(
      find.text('About 1.46 billion people live in India.'),
      findsOneWidget,
    );
    expect(find.textContaining('the most people of all 82'), findsOneWidget);
    await showCard(tester, 'quick-neighbours');
    await tapKey(tester, 'neighbour-PAK');
    expect(find.text('Pakistan'), findsOneWidget);
    await showCard(tester, 'quick-capital');
    expect(find.text('The capital of Pakistan is Islamabad.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('language-es')));
    await tester.pumpAndSettle();
    expect(find.text('La capital de Pakistán es Islamabad.'), findsOneWidget);
    expect(find.byKey(const Key('view-people')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet quick facts visual', (tester) async {
    await boot(tester, size: const Size(1280, 960));
    await pick(tester, 'IND', 'india');
    await showCard(tester, 'quick-neighbours');
    await expectLater(
      find.byKey(const Key('capture')),
      matchesGoldenFile('goldens/tablet-quick-facts.png'),
    );
  });

  testWidgets('seeing every fact unlocks a test with feedback and a score', (
    tester,
  ) async {
    await boot(tester);
    await pick(tester, 'JPN', 'japan');
    expect(
      find.text('See every fact to unlock a test · 1 of 6'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('take-test')), findsNothing);
    for (var seen = 1; seen < 6; seen++) {
      expect(find.byKey(const Key('take-test')), findsNothing);
      await tapKey(tester, 'another-fact');
    }
    await tapKey(tester, 'take-test');
    var correct = 0;
    for (var i = 1; i <= 6; i++) {
      expect(find.text('Question $i of 6'), findsOneWidget);
      await tapKey(tester, 'quiz-option-${i % 2}');
      final feedback = tester.widget<Text>(
        find.byKey(const Key('quiz-feedback')),
      );
      if (feedback.data == 'Correct!') {
        correct++;
      } else {
        expect(feedback.data, startsWith('Not quite. The answer is: '));
      }
      // Answers are locked once chosen.
      await tester.tap(find.byKey(Key('quiz-option-${(i + 1) % 2}')));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('quiz-feedback'))).data,
        feedback.data,
      );
      await tapKey(tester, 'quiz-next');
    }
    expect(find.text('$correct / 6'), findsOneWidget);
    await tapKey(tester, 'quiz-retry');
    expect(find.text('Question 1 of 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('language-es')));
    await tester.pumpAndSettle();
    expect(find.text('Pregunta 1 de 6'), findsOneWidget);
    await tapKey(tester, 'quiz-close');
    expect(find.byKey(const Key('take-test')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone test visual', (tester) async {
    await boot(tester, size: const Size(390, 844));
    await pick(tester, 'KOR', 'korea');
    for (var i = 0; i < 6; i++) {
      await tapKey(tester, 'another-fact');
    }
    await tapKey(tester, 'take-test');
    await tapKey(tester, 'quiz-option-0');
    await expectLater(
      find.byKey(const Key('capture')),
      matchesGoldenFile('goldens/phone-test.png'),
    );
  });

  test('speech reads numbers and symbols naturally', () {
    expect(
      forSpeech(
        'Japón ocupa unos 378 000 kilómetros cuadrados.',
        AppLanguage.es,
      ),
      'Japón ocupa unos 378000 kilómetros cuadrados.',
    );
    expect(
      forSpeech('About 530,000 people · World Bank', AppLanguage.en),
      'About 530000 people, World Bank',
    );
    expect(forSpeech('La Paz & Sucre', AppLanguage.en), 'La Paz and Sucre');
    expect(
      forSpeech('1.46 billion in 2025', AppLanguage.en),
      '1.46 billion in 2025',
    );
    expect(
      speechKey(AppLanguage.en, 'Mexico'),
      speechKey(AppLanguage.en, 'Mexico'),
    );
    expect(
      speechKey(AppLanguage.en, 'Mexico'),
      isNot(speechKey(AppLanguage.es, 'Mexico')),
    );
    expect(speechKey(AppLanguage.en, 'Mexico'), matches(r'^en_[0-9a-f]{16}$'));
  });

  test('everything the app can say is in the speech list', () {
    for (final language in AppLanguage.values) {
      final s = Strings(language);
      final all = allSpeech(data, s);
      void check(List<String> parts, String where) {
        for (final part in parts) {
          expect(all, contains(part), reason: '$where: $part');
        }
      }

      check(welcomeSpeech(s), 'welcome');
      for (final (i, country) in data.countries.indexed) {
        for (final card in data.cardsFor(country.id)) {
          check(cardSpeech(data, country, card, s), card.id);
        }
        final questions = buildQuiz(data, country, Random(i));
        for (final q in questions) {
          for (final answerFirst in [true, false]) {
            check(questionSpeech(q, answerFirst, s), q.question.en);
          }
          for (final correct in [true, false]) {
            check(feedbackSpeech(correct, q.answer, s), q.answer.en);
          }
        }
        final name = country.name.inLanguage(language);
        for (var score = 0; score <= questions.length; score++) {
          check(scoreSpeech(name, score, questions.length, s), country.id);
        }
      }
    }
  });

  test('every speech part has a bundled recording', () {
    final missing = [
      for (final language in AppLanguage.values)
        for (final part in allSpeech(data, Strings(language)))
          if (!clips.contains(speechKey(language, part))) part,
    ];
    // Regenerate with tool/generate_speech.sh after changing any text.
    expect(missing, isEmpty);
  });

  testWidgets('listen plays recorded parts in the chosen language', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    await boot(tester, speaker: speaker);
    await tapKey(tester, 'listen-welcome');
    expect(speaker.spoken.last.$1, 'Pick a place.');
    await pick(tester, 'MEX', 'mexico');
    await tapKey(tester, 'listen-card');
    expect(speaker.spoken.last, (
      'Mexico',
      AppLanguage.en,
      'audio/${speechKey(AppLanguage.en, 'Mexico')}.m4a',
    ));
    expect(
      find.descendant(
        of: find.byKey(const Key('listen-card')),
        matching: find.text('Stop'),
      ),
      findsOneWidget,
    );
    // Parts play one after another.
    final title = tester
        .widgetList<Text>(find.byType(Text))
        .firstWhere(
          (t) =>
              t.key is ValueKey<String> &&
              (t.key! as ValueKey<String>).value.startsWith('title-'),
        )
        .data!;
    speaker.finish();
    await tester.pumpAndSettle();
    expect(speaker.spoken.last.$1, title);
    await tapKey(tester, 'listen-card');
    expect(find.text('Stop'), findsNothing);
    await tester.tap(find.byKey(const Key('language-es')));
    await tester.pumpAndSettle();
    await tapKey(tester, 'listen-card');
    expect(speaker.spoken.last.$1, 'México');
    expect(speaker.spoken.last.$2, AppLanguage.es);
    for (var i = 0; i < 3; i++) {
      speaker.finish();
      await tester.pumpAndSettle();
    }
    expect(find.text('Detener'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read aloud speaks new cards, questions, and feedback', (
    tester,
  ) async {
    final speaker = FakeSpeaker();
    await boot(tester, speaker: speaker);
    await tapKey(tester, 'read-aloud');
    await pick(tester, 'KOR', 'korea');
    expect(speaker.spoken.last.$1, 'South Korea');
    for (var i = 0; i < 6; i++) {
      final before = speaker.spoken.length;
      await tapKey(tester, 'another-fact');
      expect(speaker.spoken.length, before + 1);
    }
    await tapKey(tester, 'take-test');
    final question = tester
        .widget<Text>(find.byKey(const Key('quiz-question')))
        .data!;
    expect(speaker.spoken.last.$1, question);
    await tapKey(tester, 'quiz-option-0');
    final feedback = tester
        .widget<Text>(find.byKey(const Key('quiz-feedback')))
        .data!;
    expect(feedback, startsWith(speaker.spoken.last.$1));
    await tapKey(tester, 'read-aloud');
    final count = speaker.spoken.length;
    await tapKey(tester, 'quiz-next');
    expect(speaker.spoken.length, count);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone Spanish fact visual', (tester) async {
    await boot(tester, size: const Size(390, 844), language: AppLanguage.es);
    await pick(tester, 'BRA', 'brasil');
    await expectLater(
      find.byKey(const Key('capture')),
      matchesGoldenFile('goldens/phone-fact-es.png'),
    );
  });
}
