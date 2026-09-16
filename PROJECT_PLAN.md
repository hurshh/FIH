# Frugal Innovation Hub — GeoInfo

Product name: GeoInfo.

## Purpose

Create a free educational app for children ages 6–16 to explore the countries of North and South America through an illustrated map. Children tap a country and discover its culture, history, wildlife, food, landmarks, and inventions in English or Latin American Spanish.

The immediate deliverable is a working prototype. App Store release is a later milestone.

## Implementation snapshot — September 9, 2026

The first Flutter prototype is implemented with an illustrated selectable map, 35 country entries, bilingual search, per-country random fact draws, language persistence, and adaptive phone/tablet layouts. Eight demonstration facts cover four countries and all six subjects; remaining content stays deferred. Maps, text, fonts, and original illustrations are bundled locally.

The web preview compiles and automated interaction/layout tests are included. Native iPhone/iPad testing remains pending because full Xcode is not installed on the development Mac. See `README.md` for running/testing instructions and `DATA_SOURCES.md` for the exact geographic deferrals and source limitations. This snapshot does not mark device testing, editorial review, or App Store release complete.

## Confirmed requirements

| Area | Decision |
| --- | --- |
| Audience | Ages 6–16 |
| Devices | iPhone and iPad |
| Framework | Flutter |
| Geographic scope | Countries in North and South America; disputed regions deferred |
| Learning topics | Culture, history, wildlife, food, landmarks, inventions |
| Interaction | Free exploration with random facts drawn from each country's mixed collection |
| Appearance | Cartoon illustrations and a simple illustrated map |
| Languages | Written English and Latin American Spanish |
| Connectivity | Everything works offline |
| Accounts | None |
| Price | Free |
| Existing resources | No existing branding, content, artwork, or development resources |
| Budget | Negotiable; scope and estimates to be established |
| Organization involvement | Frugal Innovation Hub has limited involvement |
| Success metrics | Outside the current scope |

## Proposed learning experience

1. Open directly into the Americas map, with a brief first-use gesture hint.
2. Pan and pinch to zoom; tap a country to select it and see its name.
3. Draw one random fact from that country's collection, mixing culture, history, wildlife, food, landmarks, and inventions.
4. Tap “Another fact” to draw another item from the same country's collection.
5. Switch between English and Spanish while keeping the same fact visible.
6. Return to the same map position and continue exploring.

Provide a country list as an alternative to map selection, particularly for small islands. Keep language choice and, optionally, the last map position on the device. No profile setup is necessary.

The learning experience is a mixed bag of standalone facts, with no introductory summary or expanded-reading structure. Topic labels can identify each fact, but children do not need to choose a topic before drawing. Use clear, age-appropriate language and test the presentation with younger and older children.

Proposed draw behavior: shuffle each country's available facts and draw without repeats until its collection is exhausted. Then reshuffle, avoiding an immediate repeat when more than one fact exists. Track draws for the current session; persistence across app launches is not required. A country with one fact shows that item with a friendly end-of-collection message; a country with no facts shows a clear prototype placeholder. Never substitute another country's facts.

## Scope and geographic assumptions

Treat Central America and the Caribbean as part of North America. Disputed regions are deferred and will not have selectable learning entries in the prototype. The specific exclusions and their map treatment need to be identified when selecting the map data; do not silently assign a disputed region to a country. Dependent territory coverage is a separate later decision, since dependency status does not by itself imply a territorial dispute. The initial baseline is countries.

The illustrated map must retain recognizable geography and country boundaries. Small countries and islands need enlarged touch targets, labels, or a map inset so they remain discoverable.

## Prototype and full-content release

The prototype should prove map interaction, random fact draws, language switching, and offline operation before the full content collection is produced. The user has confirmed that full content population can happen later.

Build the in-scope selectable map and country list with a small bilingual demonstration fact collection sufficient to exercise random draws and different topics. Complete country pages or six fully populated sample countries are not prerequisites. Clearly mark countries without content as previews. Choose the demonstration countries during prototype development; their selection does not change the final geographic scope.

| Deliverable | Prototype proposal | Full-content release |
| --- | --- | --- |
| Americas map | All in-scope countries selectable | All in-scope countries selectable |
| Country list and names | Complete in both languages | Complete in both languages |
| Mixed fact collections | Small bilingual demonstration collection; remaining content deferred | Reviewed collections for every in-scope country across the six subjects |
| Random fact interaction | Draw a fact and request another; handle empty and exhausted collections | Same interaction with complete content |
| Language switching | English / Latin American Spanish | Same |
| Offline operation | All prototype assets bundled | All release assets bundled |
| Device layouts | iPhone and iPad | Verified across agreed supported devices |
| Distribution | Local development build or agreed tester distribution | App Store |

Quizzes, missions, rewards, narration, accounts, multiplayer, advertising, and analytics are not part of this plan. They are not required for the requested free-exploration experience.

## Screens

- Map: pan, zoom, reset view, country selection, and language switch.
- Country list: bilingual names and direct navigation to a country.
- Country fact view: country name, one randomly drawn fact, optional illustration, topic label, “Another fact” button, and language switch.
- About/settings: language preference, credits, and app information.

Use a larger map-and-detail layout on iPad and a map-to-detail navigation flow on iPhone. The art should feel playful while remaining appealing to older children.

## Content and asset production

Create a consistent country template containing a stable country identifier, localized name, and a collection of standalone facts. Each fact has a stable identifier, one of the six topic tags, paired English and Spanish text, optional illustration references, and source/review records. The two translations represent the same fact and share its identifier.

Every child-facing label and content item must be available in both languages. Use Spanish adapted for Latin American readers, with editorial review for natural phrasing. Keep sources and review dates with the content so corrections can be traced.

The user answered yes to the content-approval question; the reviewer's identity and whether they can review both facts and Spanish wording remain unspecified. Record those details before full content approval; they do not block the interaction prototype. Research and review should address cultural specificity, historical context, and shared or disputed invention attributions. Do not invent a fact to fill a category; describe a well-supported local contribution where appropriate.

Since no resources exist, the work includes a basic visual identity, map artwork, reusable topic icons, country illustrations, English writing, Spanish translation/editing, and asset licensing records. Reuse a consistent illustration system to control production effort.

## Technical approach

Use Flutter with an app-bundled illustrated map, local country data, local fonts, and local images. Implement country selection independently from the artwork so touch areas can be adjusted for small countries.

Separate map interaction, random fact selection, content presentation, and localization. Keep country content in structured local files so additions do not require rebuilding each screen manually. Preserve the current fact identifier when switching languages instead of triggering a new draw. No server or cloud account system is needed for the agreed experience.

Test offline operation from the first launch, not only after a successful online session. Content and illustration updates will arrive with app updates under this bundled-content approach. Measure bundle size and map responsiveness during the prototype before producing the full illustration collection.

Choose exact Flutter packages, supported OS versions, and distribution setup during the technical spike after checking current compatibility. App Store publication will require a designated publishing owner and the necessary Apple developer access; it is not needed to settle the product plan.

## Delivery milestones

| Milestone | Work | Completion evidence |
| --- | --- | --- |
| 1. Scope and demonstration facts | Apply deferred-region scope and prepare a small bilingual fact collection | Recorded map scope and example facts ready for the interaction prototype |
| 2. Visual and interaction design | Establish colors, typography, map style, fact cards, and phone/tablet layouts | Reviewable map-to-fact-to-next-fact flow |
| 3. Technical spike | Build map pan/zoom, country hit testing, local fact draws, and language switching | One country works end to end on phone and tablet layouts |
| 4. Working prototype | Complete map/list, random fact interaction, empty states, and bundled demonstration assets | Installable or locally runnable prototype with documented setup |
| 5. Prototype review | Check usability across the age range, bilingual readability, small-country selection, offline behavior, and performance | Prioritized findings and fixes; scope for full content agreed |
| 6. Full content and release preparation | Complete remaining countries, bilingual review, device checks, final assets, and publishing materials | Release candidate ready for a separate publication decision |

Set a schedule and cost estimate after milestones 1–3 establish content volume, art effort, map implementation effort, and available contributors. The earlier five-to-eight-month estimate was generic and is not a commitment for this revised scope.

## Prototype acceptance checks

- App opens and all included functionality works in airplane mode on a fresh install.
- Map supports pan, pinch zoom, country selection, and reset without trapping navigation.
- Small countries and islands can be reached through the map or country list.
- Demonstration facts have matching English and Spanish text, with no unintended language mixing.
- Drawing another fact stays within the selected country and avoids repeats until its available collection is exhausted.
- Empty and single-fact collections behave clearly without broken controls or unrelated facts.
- Language changes preserve the selected country and exact fact.
- Text remains readable and controls usable on iPhone and iPad, including larger text settings.
- Country selection and fact controls have meaningful accessibility labels.
- No login or network download is required to explore.
- Prototype placeholders are clearly distinguished from completed learning content.
- Disputed regions are excluded from selectable learning entries for this stage.

## Details to settle later

1. Coverage of non-disputed dependent territories beyond the country baseline.
2. The content approver's identity and Spanish review coverage before completing the content collection.
3. The exact deferred-region list and map treatment when map data is selected.

Final app name, branding, prototype target date, budget ceiling, tester devices, and publishing ownership can be settled as the prototype work is scoped.
