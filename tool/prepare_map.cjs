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
const round = n => Math.round(n * 100) / 100;

// Each continent is an equirectangular window at 6 map units per degree.
const continents = [
  {
    id: 'americas',
    codes: 'ATG ARG BHS BRB BLZ BOL BRA CAN CHL COL CRI CUB DMA DOM ECU SLV GRD GTM GUY HTI HND JAM MEX NIC PAN PRY PER KNA LCA VCT SUR TTO USA URY VEN',
    overrides: {
      USA: ['United States', 'Estados Unidos'],
      BHS: ['Bahamas', 'Bahamas'],
      KNA: ['Saint Kitts and Nevis', 'San Cristóbal y Nieves'],
      VCT: ['Saint Vincent and the Grenadines', 'San Vicente y las Granadinas'],
    },
    continents: ['North America', 'South America'],
    region: p => (p.CONTINENT === 'South America' ? 'south' : 'north'),
    west: -170, north: 84, width: 840, height: 864,
    wrap: lon => (lon > 0 ? lon - 360 : lon),
  },
  {
    id: 'asia',
    // UN member states that Natural Earth places in Asia, plus the Maldives (filed
    // under "Seven seas"). Taiwan, Palestine, and Northern Cyprus are contextual
    // outlines covered by the disputed-area layer.
    codes: 'AFG ARM AZE BHR BGD BTN BRN KHM CHN CYP GEO IND IDN IRN IRQ ISR JPN JOR KAZ KWT KGZ LAO LBN MYS MDV MNG MMR NPL PRK OMN PAK PHL QAT SAU SGP KOR LKA SYR TJK THA TLS TUR TKM ARE UZB VNM YEM',
    overrides: {
      CHN: ['China', 'China'],
      TLS: ['Timor-Leste', 'Timor Oriental'],
    },
    continents: ['Asia'],
    region: p => ({
      'Eastern Asia': 'east-asia',
      'South-Eastern Asia': 'southeast-asia',
      'Southern Asia': 'south-asia',
      'Central Asia': 'central-asia',
      'Western Asia': 'west-asia',
    })[p.SUBREGION],
    west: 22, north: 62, width: 768, height: 450,
    wrap: lon => (lon < -30 ? lon + 360 : lon),
    // Neighbouring land is clipped to the window to keep the bundle small.
    clip: true,
    // Natural Earth's "Israel" feature covers nearly all of a UN member state.
    // It is not a disputed sub-area, so it is not masked.
    keepSelectable: ['B91'],
  },
];

// Sutherland–Hodgman clipping of a ring to the axis-aligned map window.
function clipRing(ring, w, h) {
  const edges = [
    [p => p[0] >= 0, (a, b) => [0, a[1] + (b[1] - a[1]) * (0 - a[0]) / (b[0] - a[0])]],
    [p => p[0] <= w, (a, b) => [w, a[1] + (b[1] - a[1]) * (w - a[0]) / (b[0] - a[0])]],
    [p => p[1] >= 0, (a, b) => [a[0] + (b[0] - a[0]) * (0 - a[1]) / (b[1] - a[1]), 0]],
    [p => p[1] <= h, (a, b) => [a[0] + (b[0] - a[0]) * (h - a[1]) / (b[1] - a[1]), h]],
  ];
  let out = ring;
  for (const [inside, cross] of edges) {
    const input = out;
    out = [];
    for (let i = 0; i < input.length; i++) {
      const cur = input[i], prev = input[(i + input.length - 1) % input.length];
      if (inside(cur)) {
        if (!inside(prev)) out.push(cross(prev, cur));
        out.push(cur);
      } else if (inside(prev)) out.push(cross(prev, cur));
    }
    if (!out.length) break;
  }
  return out.map(p => [round(p[0]), round(p[1])]);
}

function build(config) {
  const codes = new Set(config.codes.split(' '));
  const inContinent = f => config.continents.includes(f.properties.CONTINENT);
  const project = (lon, lat) => [round((config.wrap(lon) - config.west) * 6), round((config.north - lat) * 6)];
  const geometry = (g, clip = false) => {
    const polygons = g.type === 'Polygon' ? [g.coordinates] : g.coordinates;
    return polygons.map(polygon => polygon.map(ring => {
      let out = [];
      for (const [lon, lat] of ring) {
        const point = project(lon, lat);
        const last = out[out.length - 1];
        if (!last || Math.hypot(point[0] - last[0], point[1] - last[1]) > 0.28) out.push(point);
      }
      if (clip) out = clipRing(out, config.width, config.height);
      return out;
    }).filter(ring => ring.length >= 3)).filter(p => p.length);
  };
  const selected = countries.features.filter(f => codes.has(f.properties.ADM0_A3)).map(f => {
    const p = f.properties;
    const names = config.overrides[p.ADM0_A3] || [p.NAME_EN, p.NAME_ES];
    return {
      id: p.ADM0_A3, en: names[0], es: names[1],
      region: config.region(p),
      color: p.MAPCOLOR7 % 6,
      label: project(p.LABEL_X, p.LABEL_Y),
      polygons: geometry(f.geometry),
    };
  }).sort((a, b) => a.en.localeCompare(b.en));
  if (selected.length !== codes.size) throw new Error(`Missing ${config.id} country outlines.`);
  if (selected.some(c => !c.region)) throw new Error(`Missing ${config.id} region.`);
  const keep = new Set(config.keepSelectable || []);
  const deferred = disputed.features.filter(f => inContinent(f) && !keep.has(f.properties.BRK_A3)).map(f => ({
    id: f.properties.BRK_A3,
    name: f.properties.NAME_EN || f.properties.BRK_NAME,
    polygons: geometry(f.geometry),
  }));
  // Non-selectable geographic context. Sovereign-country entries remain separate.
  const context = config.clip
    ? countries.features.filter(f => !codes.has(f.properties.ADM0_A3))
      .map(f => ({id: f.properties.ADM0_A3, polygons: geometry(f.geometry, true)}))
      .filter(f => f.polygons.length)
    : countries.features.filter(f => inContinent(f) && !codes.has(f.properties.ADM0_A3))
      .map(f => ({id: f.properties.ADM0_A3, polygons: geometry(f.geometry)}));
  return {id: config.id, width: config.width, height: config.height, countries: selected, context, deferred};
}

const output = {
  source: 'Natural Earth, public domain; 50m countries and 10m disputed areas',
  sourceHashes: [countriesRaw, disputedRaw].map(raw => crypto.createHash('sha256').update(raw).digest('hex')),
  continents: continents.map(build),
};
fs.mkdirSync('assets/data', {recursive: true});
fs.writeFileSync('assets/data/map.json', JSON.stringify(output));
for (const c of output.continents) {
  console.log(`Prepared ${c.id}: ${c.countries.length} countries and ${c.deferred.length} deferred-area masks.`);
}
