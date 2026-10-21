# Sources and content notes

## Geography

The bundled map is derived from [Natural Earth](https://www.naturalearthdata.com/about/), whose vector map data is public domain. Source datasets:

- [1:50m admin-0 countries](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_50m_admin_0_countries.geojson)
- [1:10m admin-0 disputed areas](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_admin_0_disputed_areas.geojson)

The downloaded snapshots' SHA-256 hashes are embedded in `assets/data/map.json`. `tool/prepare_map.cjs` rounds/project coordinates and removes very short successive segments. It preserves polygon rings and provides contextual territory outlines separately from the country entries: 35 in the Americas and 47 in Asia. Asia's neighbouring land (Russia, Europe, Africa, Australia) is clipped to the map window and faded at its edges. This is a simplified educational map, not a navigation map.

Regenerate from downloaded source files with:

```sh
node tool/prepare_map.cjs /path/to/countries.geojson /path/to/disputed.geojson
```

### Deferred areas

The app subtracts the Americas features in the source disputed-area layer from selectable country geometry and draws them in neutral gray. They are also rejected by point hit testing. Non-sovereign territories are contextual outlines, not separate learning entries.

The source-layer deferrals are: Lawa Headwaters, Tigri Area, Guayana Esequiba, Guantanamo Bay Naval Base, Brazilian Island, the source's Belize claim polygon, Southern Patagonian Ice Field, Corner of Artigas, Falkland Islands, Isla Aves, Navassa Island, Bajo Nuevo Bank, Serranilla Bank, Sapodilla Cayes, and Hans Island.

The Asia map applies the same rule to the source's Asian disputed-area features, including Arunachal Pradesh, Taiwan, Gaza Strip, West Bank, Golan Heights, Abkhazia, South Ossetia, Nagorno-Karabakh, Northern Cyprus, the Kuril Islands, Paracel Islands, Spratly Islands, Scarborough Shoal, Senkaku Islands, Liancourt Rocks, Junagadh State, North Borneo, and Baikonur. One exception: the source's feature named "Israel" (`B91`) covers about 94% of Israel's territory and is not a sub-area, so it is not masked and Israel remains selectable like other UN member states. The Gaza Strip, West Bank, Golan Heights, and East Jerusalem features are masked.

**Jammu and Kashmir is a deliberate exception to the neutral policy.** At the project owner's direction (September 23, 2026), it is drawn as part of India, following India's official maps. Seven source features are transferred to India instead of masked: Kashmir (`B05`), Azad Kashmir (`B09`), Gilgit-Baltistan (`B08`), Siachen Glacier (`B45`), Aksai Chin (`B07`), Trans-Karakoram Tract (`B06`), and Demchok (`B03`). The app removes these areas from Pakistan's and China's outlines so tapping them selects India. Pakistan and China administer several of these areas, and this treatment is not neutral; confirm it with the geography reviewer and consider the App Store regions where the app will be distributed.

Asian selectable entries are UN member states. Taiwan, Palestine, and Northern Cyprus appear only as neutral, non-selectable outlines; Hong Kong and Macau are contextual outlines. The Maldives is included although the source files it under "Seven seas".

These are conservative deferrals based on the downloaded dataset, **not a statement that every listed area is currently disputed**. The layer includes leases, indeterminate areas, and historical claims. It may omit other claims. A geography reviewer should check the chosen snapshot and exact boundaries before release. Country-level entries such as Belize remain available; masked subregions are not separate selectable destinations. See Natural Earth's [boundary policy](https://www.naturalearthdata.com/about/disputed-boundaries-policy/).

## Quick facts

`assets/data/profiles.json` holds population, area, capitals, and land neighbours for every selectable country. It is generated, not hand-edited:

```sh
curl -sSLo population.json "https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&per_page=20000&mrnev=1"
curl -sSLo area.json "https://api.worldbank.org/v2/country/all/indicator/AG.SRF.TOTL.K2?format=json&per_page=20000&mrnev=1"
curl -sSLo places.geojson https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_populated_places.geojson
node tool/prepare_profiles.cjs /path/to/countries.geojson places.geojson population.json area.json
```

- **Population and area:** World Bank World Development Indicators ([SP.POP.TOTL](https://data.worldbank.org/indicator/SP.POP.TOTL), [AG.SRF.TOTL.K2](https://data.worldbank.org/indicator/AG.SRF.TOTL.K2)), CC BY 4.0, latest available year (population 2025, area 2023 in the current file). The year is shown on each card. Area is surface area including inland water. The app rounds to three significant figures.
- **Capitals:** Natural Earth 10m populated places (`Admin-0 capital`), with English and Spanish names. Corrections in the script: Astana (renamed from Nur-Sultan in 2022), Naypyidaw only for Myanmar, both Sri Jayawardenepura Kotte and Colombo for Sri Lanka, and "Washington, D.C.". Bolivia shows both La Paz and Sucre. Israel's capital is Jerusalem as recorded by Natural Earth.
- **Neighbours:** derived from the Natural Earth country outlines (two outlines sharing at least two vertices). Only UN member states are listed, so Palestine, Northern Cyprus, Taiwan, Hong Kong, Macau, and the Siachen Glacier feature are not neighbours. French Guiana appears as "France (French Guiana)". To match the map's Jammu and Kashmir treatment, India borders Afghanistan and Pakistan does not border China.

## Demonstration facts

All text is original paraphrasing. Each fact retains its source and a pending editorial-review status in `facts.json`. Spanish wording still needs human editorial review.

| Country | Fact | Source |
| --- | --- | --- |
| Brazil | Toucan beaks | [San Diego Zoo Wildlife Alliance](https://animals.sandiegozoo.org/animals/toucan) |
| Brazil | Capoeira | [UNESCO](https://ich.unesco.org/en/RL/capoeira-circle-00892) |
| Mexico | Axolotls | [San Diego Zoo Wildlife Alliance](https://animals.sandiegozoo.org/animals/axolotl) |
| Mexico | Mariachi | [UNESCO](https://ich.unesco.org/doc/src/17331-EN.pdf) |
| Mexico | Teotihuacan | [UNESCO](https://whc.unesco.org/en/list/414/) |
| Peru | Machu Picchu | [UNESCO](https://whc.unesco.org/en/list/274/) |
| Peru | Native potatoes | [International Potato Center](https://cipotato.org/potato/native-potato-varieties/) |
| United States | Basketball's origins | [Springfield College](https://springfield.edu/about/birthplace-of-basketball) |
| United States | Yellowstone, first national park | [U.S. National Park Service](https://www.nps.gov/yell/learn/historyculture/index.htm) |
| United States | First airplane flight | [Smithsonian National Air and Space Museum](https://airandspace.si.edu/collection-objects/1903-wright-flyer/nasm_A19610048000) |
| Japan | Instant noodles | [Nissin Foods](https://www.nissin.com/en_jp/about/history/) |
| Japan | Washoku | [UNESCO](https://ich.unesco.org/en/RL/washoku-traditional-dietary-cultures-of-the-japanese-notably-for-the-celebration-of-new-year-00869) |
| India | Yoga | [UNESCO](https://ich.unesco.org/en/RL/yoga-01163) |
| India | Bengal tigers | [San Diego Zoo Wildlife Alliance](https://animals.sandiegozoo.org/animals/tiger) |
| India | Durga Puja | [UNESCO](https://ich.unesco.org/en/RL/durga-puja-in-kolkata-00703) |
| China | Giant pandas | [San Diego Zoo Wildlife Alliance](https://animals.sandiegozoo.org/animals/giant-panda) |
| China | Peking opera | [UNESCO](https://ich.unesco.org/en/RL/peking-opera-00418) |
| South Korea | Kimjang | [UNESCO](https://ich.unesco.org/en/RL/kimjang-making-and-sharing-kimchi-in-the-republic-of-korea-00881) |
| South Korea | Hangul alphabet | [UNESCO Memory of the World](https://www.unesco.org/en/memory-world/hunminjeongum-manuscript) |
| South Korea | Taekkyeon | [UNESCO](https://ich.unesco.org/en/RL/taekkyeon-a-traditional-korean-martial-art-00452) |
| Indonesia | Gamelan | [UNESCO](https://ich.unesco.org/en/RL/gamelan-01607) |
| Indonesia | Komodo dragons | [San Diego Zoo Wildlife Alliance](https://animals.sandiegozoo.org/animals/komodo-dragon) |

Source URLs are displayed as text in an optional credits dialog. The app does not fetch them or require external navigation.

## Fonts and artwork

[Nunito](https://github.com/google/fonts/tree/main/ofl/nunito) and [Fraunces](https://github.com/google/fonts/tree/main/ofl/fraunces) are bundled locally under the SIL Open Font License. Their license files are in `assets/fonts/` and included in the app bundle.

Illustrations and app icons are original Flutter vector drawings. Material and Cupertino icon fonts are bundled by their Flutter packages; package license information is included in Flutter's generated license assets. Regenerate platform icons with `flutter test tool/generate_icons.dart`.
