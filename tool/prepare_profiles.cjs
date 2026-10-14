// Deterministic, offline build of per-country quick facts. Run after prepare_map.cjs.
// Usage: node tool/prepare_profiles.cjs countries.geojson places.geojson population.json area.json
const fs = require('node:fs');
const crypto = require('node:crypto');
const [countryFile, placesFile, populationFile, areaFile] = process.argv.slice(2);
if (!areaFile) throw new Error('Pass countries, populated places, World Bank population, and World Bank area files.');
const raw = [countryFile, placesFile, populationFile, areaFile].map(file => fs.readFileSync(file));
const [countries, places, population, area] = raw.map(data => JSON.parse(data));
const map = JSON.parse(fs.readFileSync('assets/data/map.json'));
const atlas = map.continents.flatMap(c => c.countries);
const names = Object.fromEntries(countries.features.map(f => [f.properties.ADM0_A3, {en: f.properties.NAME_EN, es: f.properties.NAME_ES}]));
for (const c of atlas) names[c.id] = {en: c.en, es: c.es};
names.FRA = {en: 'France (French Guiana)', es: 'Francia (Guayana Francesa)'};

// Neighbours are UN member states only, matching the selectable-country baseline.
const notNeighbours = new Set(['KAS', 'HKG', 'MAC', 'CYN', 'PSX', 'TWN']);
// Keep land borders consistent with the map's Jammu and Kashmir treatment.
const addBorders = [['IND', 'AFG']];
const removeBorders = [['PAK', 'CHN']];
// Natural Earth corrections and multiple official capitals.
const capitalOverrides = {
  KAZ: [{en: 'Astana', es: 'Astaná'}],
  MMR: [{en: 'Naypyidaw', es: 'Naipyidó'}],
  LKA: [{en: 'Sri Jayawardenepura Kotte', es: 'Sri Jayawardenapura Kotte'}, {en: 'Colombo', es: 'Colombo'}],
  USA: [{en: 'Washington, D.C.', es: 'Washington D. C.'}],
};

const points = {};
for (const f of countries.features) {
  const g = f.geometry;
  const set = new Set();
  for (const polygon of g.type === 'Polygon' ? [g.coordinates] : g.coordinates) {
    for (const ring of polygon) for (const [lon, lat] of ring) set.add(`${lon},${lat}`);
  }
  points[f.properties.ADM0_A3] = set;
}
// Countries touch when their source outlines share at least two vertices.
function touching(id) {
  const own = [...points[id]];
  return Object.keys(points).filter(other => {
    if (other === id || notNeighbours.has(other)) return false;
    let shared = 0;
    for (const key of own) if (points[other].has(key) && ++shared >= 2) return true;
    return false;
  });
}

const latest = data => new Map(data[1].filter(row => row.value != null).map(row => [row.countryiso3code, row]));
const people = latest(population);
const surface = latest(area);
const capitals = {};
for (const f of places.features) {
  const p = f.properties;
  if (p.FEATURECLA !== 'Admin-0 capital') continue;
  (capitals[p.ADM0_A3] ??= []).push({en: p.NAME_EN || p.NAME, es: p.NAME_ES || p.NAME_EN || p.NAME});
}

const profiles = {};
for (const {id} of atlas) {
  const neighbours = new Set(touching(id));
  for (const [a, b] of addBorders) if (id === a) neighbours.add(b); else if (id === b) neighbours.add(a);
  for (const [a, b] of removeBorders) if (id === a) neighbours.delete(b); else if (id === b) neighbours.delete(a);
  const pop = people.get(id), size = surface.get(id);
  const capital = capitalOverrides[id] || capitals[id];
  if (!pop || !size || !capital) throw new Error(`Missing profile data for ${id}.`);
  profiles[id] = {
    population: {value: pop.value, year: Number(pop.date)},
    area: {value: size.value, year: Number(size.date)},
    capitals: [...capital].sort((a, b) => a.en.localeCompare(b.en)),
    neighbours: [...neighbours]
      .map(n => ({id: n, ...names[n]}))
      .sort((a, b) => a.en.localeCompare(b.en)),
  };
}

const output = {
  sources: {
    population: 'World Bank, World Development Indicators SP.POP.TOTL (CC BY 4.0)',
    area: 'World Bank, World Development Indicators AG.SRF.TOTL.K2 (CC BY 4.0)',
    capitals: 'Natural Earth populated places, public domain',
    neighbours: 'Derived from Natural Earth country outlines, public domain',
  },
  sourceHashes: raw.map(data => crypto.createHash('sha256').update(data).digest('hex')),
  countries: profiles,
};
fs.writeFileSync('assets/data/profiles.json', JSON.stringify(output, null, 1) + '\n');
console.log(`Prepared quick facts for ${Object.keys(profiles).length} countries.`);
