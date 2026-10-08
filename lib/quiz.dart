import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';
import 'strings.dart';
import 'theme.dart';

const _en = Strings(AppLanguage.en), _es = Strings(AppLanguage.es);

LocalText _both(String Function(Strings s) text) =>
    LocalText(text(_en), text(_es));

/// One question per fun fact, plus one per quick fact, generated from data.
List<QuizQuestion> buildQuiz(AtlasData data, Country country, Random random) {
  final profile = data.profiles[country.id]!;
  final profiles = data.profiles;
  final byId = {for (final c in data.countries) c.id: c};
  final sameContinent = data.countries
      .where((c) => c.id != country.id && c.continent == country.continent)
      .toList();
  T pick<T>(List<T> items) => items[random.nextInt(items.length)];

  // Compare against a neighbour when possible: it's the most meaningful pair.
  Country rival(num Function(CountryProfile) measure) {
    final own = measure(profile);
    bool clear(Country c) {
      final other = measure(profiles[c.id]!);
      return max(own, other) >= min(own, other) * 1.25;
    }

    final near = profile.neighbours
        .map((n) => byId[n.id])
        .whereType<Country>()
        .where(clear)
        .toList();
    if (near.isNotEmpty) return pick(near);
    final local = sameContinent.where(clear).toList();
    return pick(
      local.isNotEmpty ? local : data.countries.where(clear).toList(),
    );
  }

  QuizQuestion compare(LocalText question, num Function(CountryProfile) m) {
    final other = rival(m);
    final ownWins = m(profile) > m(profiles[other.id]!);
    return QuizQuestion(
      question: question,
      answer: ownWins ? country.name : other.name,
      wrong: ownWins ? other.name : country.name,
    );
  }

  LocalText capitalsOf(String id) {
    final capitals = profiles[id]!.capitals;
    return LocalText(
      capitals.map((c) => c.en).join(' & '),
      capitals.map((c) => c.es).join(' y '),
    );
  }

  final neighbourIds = profile.neighbours.map((n) => n.id).toSet();
  final nearbyIds = profile.neighbours
      .where((n) => byId.containsKey(n.id))
      .map((n) => n.id)
      .toList();
  final otherCapital = pick(
    nearbyIds.isNotEmpty ? nearbyIds : sameContinent.map((c) => c.id).toList(),
  );
  return [
    for (final fact in data.factsFor(country.id))
      if (fact.quiz != null) fact.quiz!,
    QuizQuestion(
      question: _both(
        (s) => s.quizCapital(country.name.inLanguage(s.language)),
      ),
      answer: capitalsOf(country.id),
      wrong: capitalsOf(otherCapital),
    ),
    compare(_both((s) => s.quizMorePeople), (p) => p.population),
    compare(_both((s) => s.quizBigger), (p) => p.area),
    if (profile.neighbours.isEmpty)
      QuizQuestion(
        question: _both(
          (s) => s.quizAnyNeighbours(country.name.inLanguage(s.language)),
        ),
        answer: _both((s) => s.onlySea),
        wrong: _both((s) => s.yesItDoes),
      )
    else
      QuizQuestion(
        question: _both(
          (s) => s.quizNeighbour(country.name.inLanguage(s.language)),
        ),
        answer: pick(profile.neighbours).name,
        wrong: pick(
          sameContinent.where((c) => !neighbourIds.contains(c.id)).toList(),
        ).name,
      ),
  ]..shuffle(random);
}

/// A short two-option test with feedback after every answer.
class QuizCard extends StatefulWidget {
  const QuizCard({
    super.key,
    required this.country,
    required this.language,
    required this.build,
    required this.random,
    required this.onClose,
  });
  final Country country;
  final AppLanguage language;
  final List<QuizQuestion> Function() build;
  final Random random;
  final VoidCallback onClose;
  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  late List<QuizQuestion> questions;
  late List<bool> answerFirst;
  int index = 0, score = 0;
  int? picked;

  @override
  void initState() {
    super.initState();
    start();
  }

  void start() {
    questions = widget.build();
    answerFirst = [for (final _ in questions) widget.random.nextBool()];
    index = score = 0;
    picked = null;
  }

  bool get finished => index >= questions.length;

  void choose(int option) {
    if (picked != null) return;
    setState(() {
      picked = option;
      if (option == (answerFirst[index] ? 0 : 1)) score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.language);
    final name = widget.country.name.inLanguage(widget.language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.testEyebrow(name),
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              key: const Key('quiz-close'),
              tooltip: s.backToFacts,
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          ],
        ),
        if (finished) ..._results(s, name) else ..._question(s),
      ],
    );
  }

  List<Widget> _question(Strings s) {
    final q = questions[index];
    final correctOption = answerFirst[index] ? 0 : 1;
    final options = answerFirst[index]
        ? [q.answer, q.wrong]
        : [q.wrong, q.answer];
    final last = index == questions.length - 1;
    return [
      Text(
        s.questionOf(index + 1, questions.length),
        key: const Key('quiz-progress'),
        style: const TextStyle(color: muted, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: (index + (picked == null ? 0 : 1)) / questions.length,
          minHeight: 8,
          color: forest,
          backgroundColor: mint,
        ),
      ),
      const SizedBox(height: 22),
      Text(
        q.question.inLanguage(widget.language),
        key: const Key('quiz-question'),
        style: displayStyle(27),
      ),
      const SizedBox(height: 20),
      for (var i = 0; i < 2; i++) ...[
        _option(i, options[i].inLanguage(widget.language), correctOption),
        const SizedBox(height: 12),
      ],
      if (picked != null) ...[
        const SizedBox(height: 6),
        Semantics(
          liveRegion: true,
          child: Text(
            picked == correctOption
                ? s.correct
                : s.notQuite(q.answer.inLanguage(widget.language)),
            key: const Key('quiz-feedback'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: picked == correctOption ? forest : const Color(0xFFB4532F),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('quiz-next'),
            onPressed: () => setState(() {
              index++;
              picked = null;
            }),
            icon: Icon(
              last ? Icons.emoji_events_outlined : Icons.arrow_forward_rounded,
              size: 20,
            ),
            label: Text(last ? s.seeScore : s.nextQuestion),
          ),
        ),
      ],
    ];
  }

  Widget _option(int i, String label, int correctOption) {
    final answered = picked != null;
    final isCorrect = i == correctOption;
    final (background, border, icon) = !answered
        ? (Colors.white, line, null)
        : isCorrect
        ? (const Color(0xFFDCEFD9), forest, Icons.check_circle_rounded)
        : i == picked
        ? (const Color(0xFFF8DDD3), coral, Icons.cancel_rounded)
        : (Colors.white, line, null);
    return Semantics(
      button: true,
      selected: i == picked,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: border,
            width: answered && icon != null ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('quiz-option-$i'),
          onTap: answered ? null : () => choose(i),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, color: isCorrect ? forest : coral, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _results(Strings s, String name) => [
    const SizedBox(height: 8),
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events_rounded, color: forest, size: 34),
          const SizedBox(height: 12),
          Text(
            '$score / ${questions.length}',
            key: const Key('quiz-score'),
            style: displayStyle(44),
          ),
          const SizedBox(height: 4),
          Text(
            s.scoreLine(score, questions.length),
            style: const TextStyle(color: muted, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    Text(
      s.scoreMessage(name, score, questions.length),
      style: const TextStyle(fontSize: 17, height: 1.6),
    ),
    const SizedBox(height: 22),
    SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('quiz-retry'),
        onPressed: () => setState(start),
        icon: const Icon(Icons.replay_rounded, size: 20),
        label: Text(s.tryAgain),
      ),
    ),
    const SizedBox(height: 10),
    SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: widget.onClose,
        child: Text(s.backToFacts),
      ),
    ),
  ];
}
