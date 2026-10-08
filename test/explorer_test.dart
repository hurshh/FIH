import 'dart:math';

import 'package:americas_explorer/app.dart';
import 'package:americas_explorer/models.dart';
import 'package:americas_explorer/widgets/atlas_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  late AtlasData data;
  setUpAll(() async {
    data = await AtlasData.load();
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
          data: data,
          initialLanguage: language,
          random: Random(7),
          persistLanguage: persist,
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
      await pick(tester, 'CAN', 'canada');
      expect(find.text('Pronto habrá más sorpresas'), findsOneWidget);
      expect(find.byKey(const Key('another-fact')), findsNothing);
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
    await boot(tester);
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

  testWidgets('phone Spanish fact visual', (tester) async {
    await boot(tester, size: const Size(390, 844), language: AppLanguage.es);
    await pick(tester, 'BRA', 'brasil');
    await expectLater(
      find.byKey(const Key('capture')),
      matchesGoldenFile('goldens/phone-fact-es.png'),
    );
  });
}
