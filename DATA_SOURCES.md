# Sources and content notes

## Geography

The bundled map is derived from [Natural Earth](https://www.naturalearthdata.com/about/), whose vector map data is public domain. Source datasets:

- [1:50m admin-0 countries](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_50m_admin_0_countries.geojson)
- [1:10m admin-0 disputed areas](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_admin_0_disputed_areas.geojson)

The downloaded snapshots' SHA-256 hashes are embedded in `assets/data/map.json`. `tool/prepare_map.cjs` rounds/project coordinates and removes very short successive segments. It preserves polygon rings and provides contextual territory outlines separately from the 35 country entries. This is a simplified educational map, not a navigation map.

Regenerate from downloaded source files with:

```sh
node tool/prepare_map.cjs /path/to/countries.geojson /path/to/disputed.geojson
```

### Deferred areas

The app subtracts the Americas features in the source disputed-area layer from selectable country geometry and draws them in neutral gray. They are also rejected by point hit testing. Non-sovereign territories are contextual outlines, not separate learning entries.

The source-layer deferrals are: Lawa Headwaters, Tigri Area, Guayana Esequiba, Guantanamo Bay Naval Base, Brazilian Island, the source's Belize claim polygon, Southern Patagonian Ice Field, Corner of Artigas, Falkland Islands, Isla Aves, Navassa Island, Bajo Nuevo Bank, Serranilla Bank, Sapodilla Cayes, and Hans Island.

These are conservative deferrals based on the downloaded dataset, **not a statement that every listed area is currently disputed**. The layer includes leases, indeterminate areas, and historical claims. It may omit other claims. A geography reviewer should check the chosen snapshot and exact boundaries before release. Country-level entries such as Belize remain available; masked subregions are not separate selectable destinations. See Natural Earth's [boundary policy](https://www.naturalearthdata.com/about/disputed-boundaries-policy/).

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

Source URLs are displayed as text in an optional credits dialog. The app does not fetch them or require external navigation.

## Fonts and artwork

[Nunito](https://github.com/google/fonts/tree/main/ofl/nunito) and [Fraunces](https://github.com/google/fonts/tree/main/ofl/fraunces) are bundled locally under the SIL Open Font License. Their license files are in `assets/fonts/` and included in the app bundle.

Illustrations and app icons are original Flutter vector drawings. Material and Cupertino icon fonts are bundled by their Flutter packages; package license information is included in Flutter's generated license assets. Regenerate platform icons with `flutter test tool/generate_icons.dart`.
