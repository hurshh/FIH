import 'package:flutter/material.dart';

import '../models.dart';
import '../strings.dart';
import '../theme.dart';

String normalizeSearch(String value) {
  const accents = 'áéíóúüñ';
  const plain = 'aeiouun';
  var normalized = value.toLowerCase().trim();
  for (var i = 0; i < accents.length; i++) {
    normalized = normalized.replaceAll(accents[i], plain[i]);
  }
  return normalized;
}

class CountryPicker extends StatefulWidget {
  const CountryPicker({super.key, required this.data, required this.language});
  final AtlasData data;
  final AppLanguage language;
  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  String query = '';
  bool withFacts = false;
  @override
  Widget build(BuildContext context) {
    final s = Strings(widget.language);
    final compactKeyboard =
        MediaQuery.viewInsetsOf(context).bottom > 0 &&
        MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom <
            420;
    final countries =
        widget.data.countries
            .where(
              (c) =>
                  (!withFacts || widget.data.factsFor(c.id).isNotEmpty) &&
                  normalizeSearch('${c.name.en} ${c.name.es}')
                      .contains(normalizeSearch(query)),
            )
            .toList()
          ..sort(
            (a, b) => normalizeSearch(a.name.inLanguage(widget.language))
                .compareTo(normalizeSearch(b.name.inLanguage(widget.language))),
          );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, compactKeyboard ? 8 : 15, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.countries,
                          style: displayStyle(compactKeyboard ? 22 : 28),
                        ),
                      ),
                      IconButton(
                        tooltip: s.close,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: compactKeyboard ? 8 : 15),
                  TextField(
                    key: const Key('country-search'),
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      hintText: s.t(
                        'Try Mexico, Brazil, Japan…',
                        'Prueba México, Brasil, Japón…',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!compactKeyboard)
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(s.all),
                          selected: !withFacts,
                          onSelected: (_) => setState(() => withFacts = false),
                        ),
                        ChoiceChip(
                          label: Text(s.withFacts),
                          selected: withFacts,
                          onSelected: (_) => setState(() => withFacts = true),
                        ),
                      ],
                    ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: countries.isEmpty
                        ? Center(child: Text(s.noResults))
                        : ListView.separated(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: countries.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final country = countries[index];
                              final hasFacts = widget.data
                                  .factsFor(country.id)
                                  .isNotEmpty;
                              return ListTile(
                                key: ValueKey('pick-${country.id}'),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 2,
                                ),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: countryColors[country.colorIndex],
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.public_rounded,
                                    size: 24,
                                    color: ink,
                                  ),
                                ),
                                title: Text(
                                  country.name.inLanguage(widget.language),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  s.region(country.region),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: muted,
                                  ),
                                ),
                                trailing: hasFacts
                                    ? const Icon(
                                        Icons.circle,
                                        color: forest,
                                        size: 10,
                                      )
                                    : Text(
                                        s.t('Soon', 'Pronto'),
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                onTap: () => Navigator.pop(context, country),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
