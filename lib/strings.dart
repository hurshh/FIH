import 'dart:math' as math;

import 'models.dart';

class Strings {
  const Strings(this.language);
  final AppLanguage language;
  String t(String en, String es) => language == AppLanguage.en ? en : es;
  String get brand => 'GeoInfo';
  String get headline =>
      t('Big world. Little discoveries.', 'Un mundo de sorpresas.');
  String get subtitle => t(
    'Follow your curiosity. There’s a story in every place.',
    'Sigue tu curiosidad. Cada lugar tiene algo que contar.',
  );
  String get offline =>
      t('Ready for offline adventures', 'Aventuras sin conexión');
  String get explore => t('Explore', 'Explora');
  String get mapHint =>
      t('Pinch to zoom · Tap a country', 'Amplía con dos dedos · Toca un país');
  String get countries => t('Find a country', 'Busca un país');
  String get another => t('Another fact', 'Otro dato');
  String get back => t('Back to the map', 'Volver al mapa');
  String get preview =>
      t('More wonders are on their way', 'Pronto habrá más sorpresas');
  String get previewBody => t(
    'This place is on our map! Its fact collection is coming later. Explore a place with a discovery dot to try a fact.',
    '¡Este lugar ya está en el mapa! Agregaremos sus datos más adelante. Explora un país con un punto de descubrimiento para probar.',
  );
  String get welcomeTitle => t(
    'Pick a place.\nFind a little wonder.',
    'Elige un lugar.\nDescubre una sorpresa.',
  );
  String get welcomeBody => t(
    'From curious creatures to incredible inventions. Tap a country and see what turns up!',
    'Desde animales curiosos hasta inventos increíbles. ¡Toca un país y descubre qué aparece!',
  );
  String get surprise => t('Surprise me', 'Sorpréndeme');
  String get all => t('All places', 'Todos');
  String get withFacts => t('With discoveries', 'Con descubrimientos');
  String continent(String id) => switch (id) {
    'asia' => 'Asia',
    _ => t('Americas', 'Américas'),
  };
  String region(String id) => switch (id) {
    'north' => t('North America', 'América del Norte'),
    'south' => t('South America', 'América del Sur'),
    'east-asia' => t('East Asia', 'Asia oriental'),
    'southeast-asia' => t('Southeast Asia', 'Sudeste asiático'),
    'south-asia' => t('South Asia', 'Asia del Sur'),
    'central-asia' => t('Central Asia', 'Asia central'),
    'west-asia' => t('West Asia', 'Asia occidental'),
    _ => '',
  };
  String get reset => t('Reset map', 'Restablecer mapa');
  String get zoomIn => t('Zoom in', 'Acercar');
  String get zoomOut => t('Zoom out', 'Alejar');
  String get about => t('About this adventure', 'Acerca de esta aventura');
  String get close => t('Close', 'Cerrar');
  String get noResults => t(
    'No places found. Try another name.',
    'No encontramos ese lugar. Prueba otro nombre.',
  );
  String get collectionEnd => t(
    'You found our first fact here! More discoveries will be added later.',
    '¡Encontraste nuestro primer dato de este lugar! Agregaremos más descubrimientos después.',
  );
  String get people => t('People', 'Población');

  /// Rounds to three significant figures for young readers. English uses
  /// "million"/"billion"; Spanish avoids decimals and separates thousands
  /// with spaces, which reads the same across Latin America.
  String amount(num value) {
    final digits = value.round().toString().length;
    final step = digits > 3 ? math.pow(10, digits - 3).toInt() : 1;
    final n = (value / step).round() * step;
    if (language == AppLanguage.en) {
      if (n >= 1e9) return '${_trim(n / 1e9)} billion';
      if (n >= 1e6) return '${_trim(n / 1e6)} million';
      return _group(n, ',');
    }
    if (n >= 1e7) {
      return '${_group((n / 1e6).round(), ' ', minimum: 5)} millones';
    }
    return _group(n, ' ', minimum: 5);
  }

  // "1464 millones de personas", but "530 000 personas".
  String _of(String amount) =>
      amount.endsWith('millones') ? '$amount de' : amount;

  String _trim(num value) {
    final fixed = value.toStringAsFixed(value < 10 ? 2 : (value < 100 ? 1 : 0));
    return fixed.contains('.')
        ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
        : fixed;
  }

  String _group(int value, String separator, {int minimum = 4}) {
    final text = value.toString();
    if (text.length < minimum) return text;
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => separator,
    );
  }

  String ordinal(int n) {
    if (language == AppLanguage.es) return '$n.º';
    final suffix = (n % 100 >= 11 && n % 100 <= 13)
        ? 'th'
        : switch (n % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$n$suffix';
  }

  String populationSentence(String country, String amount) => t(
    'About $amount people live in $country.',
    'En $country viven unas ${_of(amount)} personas.',
  );
  String populationRank(int rank, int total) => rank == 1
      ? t(
          'That’s the most people of all $total countries on our maps!',
          '¡Es el país con más habitantes de los $total de nuestros mapas!',
        )
      : t(
          'That’s the ${ordinal(rank)} most people of the $total countries on our maps.',
          'Es el ${ordinal(rank)} país con más habitantes de los $total de nuestros mapas.',
        );
  String get areaUnit => t('square kilometers', 'kilómetros cuadrados');
  String areaSentence(String country, String amount) => t(
    '$country covers about $amount square kilometers.',
    '$country ocupa unos ${_of(amount)} kilómetros cuadrados.',
  );
  String areaRank(int rank, int total) => rank == 1
      ? t(
          'That’s the biggest of all $total countries on our maps!',
          '¡Es el más grande de los $total países de nuestros mapas!',
        )
      : t(
          'That’s the ${ordinal(rank)} biggest of the $total countries on our maps.',
          'Es el ${ordinal(rank)} más grande de los $total países de nuestros mapas.',
        );
  String capitalSentence(String country, List<String> capitals) =>
      capitals.length == 1
      ? t(
          'The capital of $country is ${capitals.single}.',
          'La capital de $country es ${capitals.single}.',
        )
      : t(
          '$country has ${capitals.length} capitals: ${capitals.join(' and ')}.',
          '$country tiene ${capitals.length} capitales: ${capitals.join(' y ')}.',
        );
  String neighbourSentence(String country, int count) => switch (count) {
    0 => t(
      '$country has no land borders. It’s surrounded by sea!',
      '$country no tiene fronteras terrestres. ¡Está rodeado de mar!',
    ),
    1 => t(
      '$country shares a land border with 1 country.',
      '$country comparte frontera terrestre con 1 país.',
    ),
    _ => t(
      '$country shares land borders with $count countries.',
      '$country comparte fronteras terrestres con $count países.',
    ),
  };
  String get tapNeighbour => t(
    'Tap a highlighted neighbor to visit it.',
    'Toca un vecino resaltado para visitarlo.',
  );
  String source(String name, [int? year]) =>
      '${t('Source', 'Fuente')}: $name${year == null ? '' : ' · $year'}';
  String get worldBank => t('World Bank', 'Banco Mundial');
  String get naturalEarth => 'Natural Earth';

  String topic(String topic) => switch (topic) {
    'wildlife' => t('Wildlife', 'Vida silvestre'),
    'culture' => t('Culture', 'Cultura'),
    'history' => t('History', 'Historia'),
    'food' => t('Food', 'Comida'),
    'landmarks' => t('Landmarks', 'Lugares emblemáticos'),
    'inventions' => t('Inventions', 'Inventos'),
    _ => t('Discovery', 'Descubrimiento'),
  };
}
