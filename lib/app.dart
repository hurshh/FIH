import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models.dart';
import 'strings.dart';
import 'theme.dart';
import 'widgets/atlas_map.dart';
import 'widgets/country_picker.dart';
import 'quiz.dart';
import 'widgets/discovery_art.dart';

class AtlasApp extends StatefulWidget {
  const AtlasApp({
    super.key,
    required this.data,
    this.initialLanguage = AppLanguage.en,
    this.persistLanguage,
    this.random,
  });
  final AtlasData data;
  final AppLanguage initialLanguage;
  final Future<void> Function(AppLanguage)? persistLanguage;
  final Random? random;
  @override
  State<AtlasApp> createState() => _AtlasAppState();
}

class _AtlasAppState extends State<AtlasApp> {
  late AppLanguage language = widget.initialLanguage;
  Future<void> saves = Future.value();
  final messenger = GlobalKey<ScaffoldMessengerState>();

  void changeLanguage(AppLanguage value) {
    if (value == language) return;
    setState(() => language = value);
    // Serialize writes so fast taps cannot restore an older setting on launch.
    saves = saves.then((_) async {
      try {
        await widget.persistLanguage?.call(value);
      } catch (_) {
        messenger.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              Strings(language).t(
                'Your language changed, but could not be saved for next time.',
                'El idioma cambió, pero no se pudo guardar para la próxima vez.',
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GeoInfo',
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: messenger,
    theme: atlasTheme(),
    locale: Locale(language.name),
    supportedLocales: const [Locale('en'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ExplorerHome(
      data: widget.data,
      language: language,
      onLanguage: changeLanguage,
      random: widget.random,
    ),
  );
}

class ExplorerHome extends StatefulWidget {
  const ExplorerHome({
    super.key,
    required this.data,
    required this.language,
    required this.onLanguage,
    this.random,
  });
  final AtlasData data;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguage;
  final Random? random;
  @override
  State<ExplorerHome> createState() => _ExplorerHomeState();
}

class _ExplorerHomeState extends State<ExplorerHome> {
  late final FactBag bag = FactBag(random: widget.random);
  late final Random random = widget.random ?? Random();
  late String continent = widget.data.continents.first.id;
  Country? selected;
  DiscoveryCard? fact;
  // Cards each country has shown this session; seeing all unlocks its test.
  final seenFacts = <String, Set<String>>{};
  bool testing = false;

  void _recordSeen() {
    final country = selected, card = fact;
    if (country == null || card == null) return;
    (seenFacts[country.id] ??= {}).add(card.id);
  }

  (int, int) _progress(Country country) => (
    seenFacts[country.id]?.length ?? 0,
    widget.data.cardsFor(country.id).length,
  );
  final factScroll = ScrollController();
  Strings get s => Strings(widget.language);

  @override
  void dispose() {
    factScroll.dispose();
    super.dispose();
  }

  void select(Country country) {
    setState(() {
      continent = country.continent;
      selected = country;
      fact =
          bag.current(country.id) ??
          bag.draw(country.id, widget.data.cardsFor(country.id));
      testing = false;
      _recordSeen();
    });
    if (factScroll.hasClients) factScroll.jumpTo(0);
  }

  void nextFact() {
    if (selected == null) return;
    setState(() {
      fact = bag.draw(selected!.id, widget.data.cardsFor(selected!.id));
      _recordSeen();
    });
    if (factScroll.hasClients) factScroll.jumpTo(0);
  }

  void surprise() {
    final available = widget.data.countries
        .where((c) => widget.data.factsFor(c.id).isNotEmpty)
        .toList();
    if (available.length > 1) {
      available.removeWhere((c) => c.id == selected?.id);
    }
    if (available.isNotEmpty) {
      select(available[random.nextInt(available.length)]);
    }
  }

  Future<void> findCountry() async {
    final country = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) =>
          CountryPicker(data: widget.data, language: widget.language),
    );
    if (country != null && mounted) select(country);
  }

  void showAbout() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(s.about, style: displayStyle(25)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.t(
                'A little atlas for big curiosity. Made for Frugal Innovation Hub.',
                'Un pequeño atlas para una gran curiosidad. Creado para Frugal Innovation Hub.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.t(
                'Explore freely in English or Spanish. Maps, illustrations, and facts are included in the app. Only your language preference is saved on this device.',
                'Explora libremente en inglés o español. Los mapas, las ilustraciones y los datos están incluidos en la app. Solo se guarda tu preferencia de idioma en este dispositivo.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.t(
                'This is an early preview with a small sample of facts. More content will come later. Some regions are reserved for a later version.',
                'Esta es una versión de prueba con algunos datos de ejemplo. Agregaremos más contenido después. Algunas regiones se reservan para una versión futura.',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.t(
                'Map, capitals, and neighbors: Natural Earth (public domain). Population and area: World Bank (CC BY 4.0). Fonts: Nunito and Fraunces (SIL Open Font License). Illustrations: original vector artwork. Facts: source credits appear on each card; editorial review is pending.',
                'Mapa, capitales y vecinos: Natural Earth (dominio público). Población y superficie: Banco Mundial (CC BY 4.0). Tipografías: Nunito y Fraunces (SIL Open Font License). Ilustraciones: arte vectorial original. Datos: cada tarjeta indica su fuente; la revisión editorial está pendiente.',
              ),
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.close),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final shortScreen = constraints.maxHeight < 540;
      final compact = constraints.maxWidth < 600 || shortScreen;
      final phoneDetail = !wide && selected != null;
      return PopScope(
        canPop: !phoneDetail,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && selected != null) setState(() => selected = null);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(compact),
                      if (!phoneDetail && !shortScreen)
                        Padding(
                          padding: EdgeInsets.only(
                            top: compact ? 12 : 23,
                            bottom: compact ? 18 : 26,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.headline,
                                style: displayStyle(compact ? 30 : 43),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                s.subtitle,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: compact ? 14 : 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (phoneDetail)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextButton.icon(
                            key: const Key('back-to-map'),
                            onPressed: () => setState(() => selected = null),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                            ),
                            label: Text(s.back),
                          ),
                        ),
                      Expanded(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 7, child: _map()),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 4, child: _panel()),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned.fill(
                                    child: Offstage(
                                      offstage: phoneDetail,
                                      child: _map(),
                                    ),
                                  ),
                                  if (phoneDetail)
                                    Positioned.fill(child: _panel()),
                                ],
                              ),
                      ),
                      if (!phoneDetail) _footer(compact),
                      if (phoneDetail) const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _header(bool compact) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: forest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.public_rounded,
            color: Color(0xFFF8E8AE),
            size: 28,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.brand, style: displayStyle(compact ? 19 : 24)),
              if (!compact)
                const Text(
                  'FRUGAL INNOVATION HUB',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    color: muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        if (!compact) ...[
          const Icon(Icons.offline_bolt_outlined, color: forest, size: 18),
          const SizedBox(width: 6),
          Text(s.offline, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(width: 24),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEEEFE6),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: AppLanguage.values
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.all(3),
                    child: Semantics(
                      selected: value == widget.language,
                      child: TextButton(
                        key: Key('language-${value.name}'),
                        onPressed: () => widget.onLanguage(value),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: value == widget.language
                              ? Colors.white
                              : Colors.transparent,
                          foregroundColor: value == widget.language
                              ? forest
                              : muted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(
                          value.name.toUpperCase(),
                          semanticsLabel: value == AppLanguage.en
                              ? 'English'
                              : 'Español',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          IconButton(
            tooltip: s.about,
            onPressed: showAbout,
            icon: const Icon(Icons.info_outline_rounded, size: 21),
          ),
        ],
      ],
    ),
  );

  Widget _map() => AtlasMap(
    key: const ValueKey('atlas-map'),
    data: widget.data,
    continent: widget.data.continent(continent),
    language: widget.language,
    selectedId: selected?.id,
    onSelect: select,
    onContinent: (id) => setState(() => continent = id),
    onFind: findCountry,
  );

  Widget _footer(bool compact) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        OutlinedButton.icon(
          key: const Key('country-list'),
          onPressed: findCountry,
          icon: const Icon(Icons.travel_explore_rounded, size: 18),
          label: Text(s.countries),
        ),
        const SizedBox(width: 10),
        if (compact)
          Expanded(
            child: TextButton(onPressed: surprise, child: Text(s.surprise)),
          )
        else
          Expanded(
            child: Text(
              s.t(
                'No rush. No scores. Just a world to explore.',
                'Sin prisas ni puntajes. Solo un mundo por explorar.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ),
        IconButton(
          tooltip: s.about,
          onPressed: showAbout,
          icon: const Icon(Icons.info_outline_rounded, size: 20),
        ),
      ],
    ),
  );

  Widget _panel() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: line),
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      controller: factScroll,
      padding: const EdgeInsets.all(22),
      child: selected == null
          ? _welcome()
          : testing
          ? QuizCard(
              key: ValueKey('quiz-${selected!.id}'),
              country: selected!,
              language: widget.language,
              random: random,
              build: () => buildQuiz(widget.data, selected!, random),
              onClose: () => setState(() => testing = false),
            )
          : _factContent(),
    ),
  );

  Widget _welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _eyebrow(
        s.t(
          'A LITTLE CURIOSITY GOES A LONG WAY',
          'LA CURIOSIDAD TE LLEVA LEJOS',
        ),
      ),
      const SizedBox(height: 20),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: const DiscoveryArt(height: 220),
      ),
      const SizedBox(height: 25),
      Text(s.welcomeTitle, style: displayStyle(31)),
      const SizedBox(height: 14),
      Text(
        s.welcomeBody,
        style: const TextStyle(color: muted, fontSize: 15, height: 1.6),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('surprise'),
          onPressed: surprise,
          icon: const Icon(Icons.auto_awesome_rounded, size: 19),
          label: Text(s.surprise),
        ),
      ),
      const SizedBox(height: 23),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          'wildlife',
          'food',
          'culture',
          'history',
          'landmarks',
          'inventions',
        ].map((topic) => _topicChip(topic)).toList(),
      ),
    ],
  );

  Widget _factContent() {
    final country = selected!;
    final current = fact;
    final funFact = current is DiscoveryFact ? current : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _eyebrow(
                s.t('YOUR NEXT DISCOVERY', 'TU PRÓXIMO DESCUBRIMIENTO'),
              ),
            ),
            IconButton(
              key: const Key('close-country'),
              tooltip: s.back,
              onPressed: () => setState(() => selected = null),
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          ],
        ),
        Text(
          country.name.inLanguage(widget.language),
          key: const Key('country-name'),
          style: displayStyle(31),
        ),
        const SizedBox(height: 4),
        Text(
          s.region(country.region),
          style: const TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        _testPrompt(country),
        const SizedBox(height: 19),
        if (current is QuickFact) ...[
          ..._quickFact(country, current.kind),
          const SizedBox(height: 10),
          _anotherFact(country),
        ] else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: DiscoveryArt(
              scene: funFact?.art ?? 'mountains',
              height: 205,
            ),
          ),
          const SizedBox(height: 22),
          if (funFact != null) ...[
            _topicChip(funFact.topic),
            const SizedBox(height: 13),
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    funFact.title.inLanguage(widget.language),
                    key: ValueKey('title-${funFact.id}'),
                    style: displayStyle(28),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    funFact.body.inLanguage(widget.language),
                    key: ValueKey('body-${funFact.id}'),
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.65,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _anotherFact(country),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    s.t(
                      'Behind this discovery',
                      'Detrás de este descubrimiento',
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(funFact.sourceName),
                        const SizedBox(height: 12),
                        SelectableText(
                          funFact.sourceUrl,
                          style: const TextStyle(fontSize: 13, color: muted),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.t(
                            'Sample content · Editorial review pending',
                            'Contenido de ejemplo · Revisión editorial pendiente',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.close),
                    ),
                  ],
                ),
              ),
              child: Text(
                '${s.t('Source', 'Fuente')}: ${funFact.sourceName}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ] else ...[
            _eyebrow(s.t('A PLACE TO DISCOVER', 'UN LUGAR POR DESCUBRIR')),
            const SizedBox(height: 12),
            Text(s.preview, style: displayStyle(29)),
            const SizedBox(height: 14),
            Text(
              s.previewBody,
              style: const TextStyle(color: muted, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: surprise,
                icon: const Icon(Icons.auto_awesome_rounded, size: 19),
                label: Text(s.surprise),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _anotherFact(Country country) =>
      widget.data.cardsFor(country.id).length > 1
      ? SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('another-fact'),
            onPressed: nextFact,
            icon: const Icon(Icons.shuffle_rounded, size: 20),
            label: Text(s.another),
          ),
        )
      : Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(s.collectionEnd, style: const TextStyle(fontSize: 14)),
        );

  Widget _testPrompt(Country country) {
    final (done, total) = _progress(country);
    if (done < total) {
      return Row(
        key: const Key('test-locked'),
        children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: muted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              s.unlockProgress(done, total),
              style: const TextStyle(color: muted, fontSize: 13),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('take-test'),
        onPressed: () {
          setState(() => testing = true);
          if (factScroll.hasClients) factScroll.jumpTo(0);
        },
        icon: const Icon(Icons.quiz_outlined, size: 20),
        label: Text(s.takeTest),
      ),
    );
  }

  List<Widget> _quickFact(Country country, QuickKind kind) {
    final profile = widget.data.profiles[country.id];
    if (profile == null) return const [];
    final name = country.name.inLanguage(widget.language);
    final total = widget.data.profiles.length;
    final (icon, headline, unit, lines, source) = switch (kind) {
      QuickKind.people => (
        Icons.groups_rounded,
        s.amount(profile.population),
        s.people.toLowerCase(),
        [
          s.populationSentence(name, s.amount(profile.population)),
          s.populationRank(
            widget.data.rank(country.id, (p) => p.population),
            total,
          ),
        ],
        s.source(s.worldBank, profile.populationYear),
      ),
      QuickKind.size => (
        Icons.square_foot_rounded,
        s.amount(profile.area),
        s.areaUnit,
        [
          s.areaSentence(name, s.amount(profile.area)),
          s.areaRank(widget.data.rank(country.id, (p) => p.area), total),
        ],
        s.source(s.worldBank, profile.areaYear),
      ),
      QuickKind.capital => (
        Icons.account_balance_outlined,
        profile.capitals
            .map((c) => c.inLanguage(widget.language))
            .join(s.t(' & ', ' y ')),
        null,
        [
          s.capitalSentence(
            name,
            profile.capitals.map((c) => c.inLanguage(widget.language)).toList(),
          ),
        ],
        s.source(s.naturalEarth),
      ),
      QuickKind.neighbours => (
        Icons.share_location_rounded,
        '${profile.neighbours.length}',
        s.t('land neighbors', 'vecinos terrestres'),
        [s.neighbourSentence(name, profile.neighbours.length)],
        s.source(s.naturalEarth),
      ),
    };
    final visitable = {for (final c in widget.data.countries) c.id: c};
    return [
      Semantics(
        liveRegion: true,
        child: Container(
          key: Key('quick-${kind.name}'),
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: forest, size: 30),
              const SizedBox(height: 12),
              Text(headline, style: displayStyle(34)),
              if (unit != null) ...[
                const SizedBox(height: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      for (final (i, line) in lines.indexed) ...[
        Text(
          line,
          key: i == 0
              ? ValueKey('body-${QuickFact(country.id, kind).id}')
              : null,
          style: const TextStyle(fontSize: 17, height: 1.6),
        ),
        const SizedBox(height: 10),
      ],
      if (kind == QuickKind.neighbours && profile.neighbours.isNotEmpty) ...[
        const SizedBox(height: 4),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final n in profile.neighbours)
              visitable[n.id] == null
                  ? Chip(
                      label: Text(n.name.inLanguage(widget.language)),
                      labelStyle: const TextStyle(color: muted),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: line),
                    )
                  : ActionChip(
                      key: Key('neighbour-${n.id}'),
                      avatar: const Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: forest,
                      ),
                      label: Text(n.name.inLanguage(widget.language)),
                      labelStyle: const TextStyle(
                        color: forest,
                        fontWeight: FontWeight.w800,
                      ),
                      backgroundColor: mint,
                      side: BorderSide.none,
                      onPressed: () => select(visitable[n.id]!),
                    ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          s.tapNeighbour,
          style: const TextStyle(color: muted, fontSize: 13),
        ),
      ],
      const SizedBox(height: 12),
      Text(source, style: const TextStyle(fontSize: 11, color: muted)),
    ];
  }

  Widget _eyebrow(String value) => Text(
    value,
    style: const TextStyle(
      color: muted,
      fontSize: 10,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w900,
    ),
  );

  Widget _topicChip(String topic) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: mint,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch (topic) {
            'wildlife' => Icons.pets_outlined,
            'food' => Icons.restaurant_rounded,
            'culture' => Icons.music_note_rounded,
            'history' => Icons.hourglass_bottom_rounded,
            'landmarks' => Icons.landscape_outlined,
            _ => Icons.lightbulb_outline_rounded,
          },
          size: 13,
          color: forest,
        ),
        const SizedBox(width: 5),
        Text(
          s.topic(topic),
          style: const TextStyle(
            color: forest,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
