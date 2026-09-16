// Deterministic, offline conversion of the two Natural Earth source downloads.
// Usage: node tool/prepare_map.cjs countries.geojson disputed.geojson
const fs = require('node:fs');
const crypto = require('node:crypto');
const [countryFile, disputedFile] = process.argv.slice(2);
if (!countryFile || !disputedFile) throw new Error('Pass country and disputed-area GeoJSON files.');
const countriesRaw = fs.readFileSync(countryFile);
const disputedRaw = fs.readFileSync(disputedFile);
const countries = JSON.parse(countriesRaw);
const disputed = JSON.parse(disputedRaw);
const codes = new Set('ATG ARG BHS BRB BLZ BOL BRA CAN CHL COL CRI CUB DMA DOM ECU SLV GRD GTM GUY HTI HND JAM MEX NIC PAN PRY PER KNA LCA VCT SUR TTO USA URY VEN'.split(' '));
const overrides = {
  USA: ['United States', 'Estados Unidos'],
  BHS: ['Bahamas', 'Bahamas'],
  KNA: ['Saint Kitts and Nevis', 'San Cristóbal y Nieves'],
  VCT: ['Saint Vincent and the Grenadines', 'San Vicente y las Granadinas'],
};
const inAmericas = f => ['North America', 'South America'].includes(f.properties.CONTINENT);
const round = n => Math.round(n * 100) / 100;
function geometry(g) {
  const polygons = g.type === 'Polygon' ? [g.coordinates] : g.coordinates;
  return polygons.map(polygon => polygon.map(ring => {
    const out = [];
    for (const [rawLon, lat] of ring) {
      const lon = rawLon > 0 ? rawLon - 360 : rawLon;
      const point = [round((lon + 170) * 6), round((84 - lat) * 6)];
      const last = out[out.length - 1];
      if (!last || Math.hypot(point[0] - last[0], point[1] - last[1]) > 0.28) out.push(point);
    }
    return out;
  }).filter(ring => ring.length >= 3)).filter(p => p.length);
}
const selected = countries.features.filter(f => codes.has(f.properties.ADM0_A3)).map(f => {
  const p = f.properties;
  const names = overrides[p.ADM0_A3] || [p.NAME_EN, p.NAME_ES];
  return {
    id: p.ADM0_A3, en: names[0], es: names[1],
    region: p.CONTINENT === 'South America' ? 'south' : 'north',
    color: p.MAPCOLOR7 % 6,
    label: [round((p.LABEL_X + 170) * 6), round((84 - p.LABEL_Y) * 6)],
    polygons: geometry(f.geometry),
  };
}).sort((a, b) => a.en.localeCompare(b.en));
if (selected.length !== codes.size) throw new Error('Missing country outlines.');
const deferred = disputed.features.filter(inAmericas).map(f => ({
  id: f.properties.BRK_A3,
  name: f.properties.NAME_EN || f.properties.BRK_NAME,
  polygons: geometry(f.geometry),
}));
// Non-selectable geographic context. Sovereign-country entries remain separate.
const context = countries.features.filter(f => inAmericas(f) && !codes.has(f.properties.ADM0_A3))
  .map(f => ({id: f.properties.ADM0_A3, polygons: geometry(f.geometry)}));
const output = {
  width: 840, height: 864,
  source: 'Natural Earth, public domain; 50m countries and 10m disputed areas',
  sourceHashes: [countriesRaw, disputedRaw].map(raw => crypto.createHash('sha256').update(raw).digest('hex')),
  countries: selected, context, deferred,
};
fs.mkdirSync('assets/data', {recursive: true});
fs.writeFileSync('assets/data/map.json', JSON.stringify(output));
console.log(`Prepared ${selected.length} countries and ${deferred.length} deferred-area masks.`);
