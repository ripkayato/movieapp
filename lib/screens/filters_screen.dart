import 'package:flutter/material.dart';

class FiltersScreen extends StatefulWidget {
  final List<String> selectedGenres;
  final List<String> selectedTypes;
  final List<String> selectedActors;
  final List<String> allGenres;
  final List<String> allTypes;
  final List<String> allActors;
  final int? minDuration;
  final int? maxDuration;
  final int? yearFilter;

  const FiltersScreen({
    super.key,
    required this.selectedGenres,
    required this.selectedTypes,
    required this.selectedActors,
    required this.allGenres,
    required this.allTypes,
    required this.allActors,
    this.minDuration,
    this.maxDuration,
    this.yearFilter,
  });

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late List<String> genres;
  late List<String> types;
  late List<String> actors;
  int? minDuration;
  int? maxDuration;
  int? yearFilter;

  @override
  void initState() {
    super.initState();
    genres = List.from(widget.selectedGenres);
    types = List.from(widget.selectedTypes);
    actors = List.from(widget.selectedActors);
    minDuration = widget.minDuration;
    maxDuration = widget.maxDuration;
    yearFilter = widget.yearFilter;
  }

  void clearFilters() {
    setState(() {
      genres.clear();
      types.clear();
      actors.clear();
      minDuration = null;
      maxDuration = null;
      yearFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильтры'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text('Жанры'),
            children: widget.allGenres.map((g) {
              return CheckboxListTile(
                title: Text(g),
                value: genres.contains(g),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      genres.add(g);
                    } else {
                      genres.remove(g);
                    }
                  });
                },
              );
            }).toList(),
          ),
          ExpansionTile(
            title: const Text('Тип'),
            children: widget.allTypes.map((t) {
              return CheckboxListTile(
                title: Text(t),
                value: types.contains(t),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      types.add(t);
                    } else {
                      types.remove(t);
                    }
                  });
                },
              );
            }).toList(),
          ),
          ExpansionTile(
            title: const Text('Актеры'),
            children: widget.allActors.map((a) {
              return CheckboxListTile(
                title: Text(a),
                value: actors.contains(a),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      actors.add(a);
                    } else {
                      actors.remove(a);
                    }
                  });
                },
              );
            }).toList(),
          ),
          ListTile(
            title: const Text('Минимальная длительность (мин)'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'мин'),
                onChanged: (v) => setState(() => minDuration = int.tryParse(v)),
              ),
            ),
          ),
          ListTile(
            title: const Text('Максимальная длительность (мин)'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'мин'),
                onChanged: (v) => setState(() => maxDuration = int.tryParse(v)),
              ),
            ),
          ),
          ListTile(
            title: const Text('Год'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'год'),
                onChanged: (v) => setState(() => yearFilter = int.tryParse(v)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Поиск', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(context, {
                        'genres': genres,
                        'types': types,
                        'actors': actors,
                        'minDuration': minDuration,
                        'maxDuration': maxDuration,
                        'yearFilter': yearFilter,
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text('Очистить фильтр'),
                    onPressed: clearFilters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}