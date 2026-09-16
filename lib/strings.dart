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
  String get explore => t('Explore the Americas', 'Explora las Américas');
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
  String get north => t('North America', 'América del Norte');
  String get south => t('South America', 'América del Sur');
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
