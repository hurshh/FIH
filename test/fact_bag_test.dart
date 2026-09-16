import 'dart:math';

import 'package:americas_explorer/models.dart';
import 'package:flutter_test/flutter_test.dart';

DiscoveryFact sample(String id, {String country = 'BRA'}) => DiscoveryFact(
  id: id,
  countryId: country,
  topic: 'wildlife',
  title: const LocalText('Title', 'Título'),
  body: const LocalText('Body', 'Texto'),
  art: 'toucan',
  sourceName: 'Test',
  sourceUrl: 'https://example.org',
);

void main() {
  test(
    'draws every fact once per cycle without immediate boundary repeats',
    () {
      final bag = FactBag(random: Random(4));
      final facts = List.generate(5, (i) => sample('$i'));
      String? previous;
      for (var cycle = 0; cycle < 30; cycle++) {
        final ids = <String>{};
        for (var draw = 0; draw < facts.length; draw++) {
          final fact = bag.draw('BRA', facts)!;
          expect(fact.id, isNot(previous));
          expect(ids.add(fact.id), isTrue);
          previous = fact.id;
        }
        expect(ids.length, facts.length);
      }
    },
  );
  test('countries have independent collections and last facts', () {
    final bag = FactBag(random: Random(2));
    final brazil = [sample('a'), sample('b')];
    final mexico = [sample('c', country: 'MEX')];
    final first = bag.draw('BRA', brazil)!;
    expect(bag.draw('MEX', mexico)!.countryId, 'MEX');
    expect(bag.current('BRA'), same(first));
    expect(bag.draw('BRA', brazil)!.id, isNot(first.id));
  });
  test('empty and one-item collections are safe', () {
    final bag = FactBag();
    expect(bag.draw('CAN', []), isNull);
    final one = sample('only');
    expect(bag.draw('BRA', [one]), same(one));
    expect(bag.draw('BRA', [one]), same(one));
  });
}
