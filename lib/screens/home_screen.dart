// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import 'movie_detail_screen.dart';
import 'filters_screen.dart';
import 'notes_screen.dart';
import 'add_movie_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart'; // ← ВАЖНО!

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;
  final bool pushEnabled;
  final ValueChanged<bool> onPushToggle;
  final String nickname;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.themeMode,
    required this.pushEnabled,
    required this.onPushToggle,
    required this.nickname,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = '';
  List<String> selectedGenres = [];
  List<String> selectedTypes = [];
  List<String> selectedActors = [];
  int? minDuration;
  int? maxDuration;
  int? yearFilter;
  String sortBy = 'Название';

  final List<String> allGenres = [
    'Фантастика', 'Драма', 'Детектив', 'Боевик', 'Комедия',
    'Триллер', 'Мелодрама', 'Ужасы', 'Анимация', 'Фэнтези'
  ];
  final List<String> allTypes = ['Фильм', 'Сериал'];
  final List<String> allActors = [
    'Мэттью МакКонахи', 'Энн Хэтэуэй', 'Киану Ривз', 'Том Хэнкс',
    'Леонардо ДиКаприо', 'Кристиан Бэйл', 'Брэд Питт'
  ];

  final MovieService _movieService = MovieService();

  List<Movie> filterMovies(List<Movie> movies) {
    return movies.where((m) {
      if (search.isNotEmpty && !m.title.toLowerCase().contains(search.toLowerCase())) return false;
      if (selectedGenres.isNotEmpty && !selectedGenres.contains(m.genre)) return false;
      if (selectedTypes.isNotEmpty && !selectedTypes.contains(m.type)) return false;
      if (selectedActors.isNotEmpty && !m.actors.any((a) => selectedActors.contains(a))) return false;
      if (minDuration != null && m.duration < minDuration!) return false;
      if (maxDuration != null && m.duration > maxDuration!) return false;
      if (yearFilter != null && m.year != yearFilter) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        switch (sortBy) {
          case 'Рейтинг':
            return (b.rating ?? 0).compareTo(a.rating ?? 0);
          case 'Год':
            return b.year.compareTo(a.year);
          default:
            return a.title.compareTo(b.title);
        }
      });
  }

  void openFilters() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FiltersScreen(
          selectedGenres: selectedGenres,
          selectedTypes: selectedTypes,
          selectedActors: selectedActors,
          allGenres: allGenres,
          allTypes: allTypes,
          allActors: allActors,
          minDuration: minDuration,
          maxDuration: maxDuration,
          yearFilter: yearFilter,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        selectedGenres = result['genres'] ?? [];
        selectedTypes = result['types'] ?? [];
        selectedActors = result['actors'] ?? [];
        minDuration = result['minDuration'];
        maxDuration = result['maxDuration'];
        yearFilter = result['yearFilter'];
      });
    }
  }

  void clearFilters() {
    setState(() {
      selectedGenres.clear();
      selectedTypes.clear();
      selectedActors.clear();
      minDuration = null;
      maxDuration = null;
      yearFilter = null;
      search = '';
    });
  }

  Future<void> _toggleFavoriteFromList(Movie movie) async {
    try {
      // Копируем фильм и переключаем favorite
      final updatedMovie = movie.copyWith(favorite: !movie.favorite);
      
      // Определяем, какой ID использовать
      String? docId;
      
      // Если это глобальный фильм с личной записью
      if (movie.movieId != null) {
        docId = movie.id; // ID из личной коллекции
      } else if (movie.id != null) {
        // Это пользовательский фильм
        docId = movie.id;
      }
      
      if (docId != null) {
        // НЕ вызываем setState, просто отправляем в Firestore
        // UI обновится автоматически через Stream когда Firestore вернет данные
        try {
          await _movieService.updateMovieNote(docId, updatedMovie);
        } catch (e) {
          // Если ошибка при сохранении, показываем уведомление
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          themeMode: widget.themeMode,
          pushEnabled: widget.pushEnabled,
          onPushToggle: widget.onPushToggle,
          onThemeToggle: widget.onThemeToggle,
          nickname: widget.nickname,
          onLogout: widget.onLogout,
        ),
      ),
    );
    setState(() {});
  }

  Future<List<Movie>> getMoviesByStatus(bool Function(Movie) filter) async {
    // Получаем фильмы из личной коллекции пользователя (там есть личные поля)
    final movies = await _movieService.getMyMovies().first;
    return movies.where(filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white;
    final appBarForeground = Colors.redAccent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Привет, ${widget.nickname}!'),
        backgroundColor: appBarColor,
        foregroundColor: appBarForeground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // ЛИЧНЫЙ КАБИНЕТ В ВЕРХНЕМ УГЛУ
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            tooltip: 'Личный кабинет (сервер)',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(onLogout: widget.onLogout),
              ),
            ),
          ),
          // ТЕМА
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
          // ФИЛЬТРЫ
          IconButton(icon: const Icon(Icons.filter_list), onPressed: openFilters),
          // ОЧИСТИТЬ
          IconButton(icon: const Icon(Icons.clear), tooltip: 'Очистить', onPressed: clearFilters),
          // ИЗБРАННОЕ
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              final fav = await getMoviesByStatus((m) => m.favorite);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NotesScreen(movies: fav, title: 'Избранное')));
            },
          ),
          // ПРОСМОТРЕННОЕ
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () async {
              final watched = await getMoviesByStatus((m) => m.watched);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NotesScreen(movies: watched, title: 'Просмотренное')));
            },
          ),
          // ХОЧУ ПОСМОТРЕТЬ
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () async {
              final want = await getMoviesByStatus((m) => m.wantToWatch);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NotesScreen(movies: want, title: 'Хочу посмотреть')));
            },
          ),
          // НАСТРОЙКИ
          IconButton(icon: const Icon(Icons.settings), onPressed: openSettings),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortBy,
                  items: ['Название', 'Рейтинг', 'Год']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => sortBy = v ?? 'Название'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Movie>>(
              stream: _movieService.getAllMovies(), // Объединённый список (глобальные + личные данные)
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Ошибка в StreamBuilder: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Ошибка загрузки: ${snapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final movies = snapshot.data ?? [];
                if (movies.isEmpty) {
                  return const Center(
                    child: Text('Нет фильмов. Добавьте первый фильм!'),
                  );
                }
                
                final filtered = filterMovies(movies);
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () async {
                            await _toggleFavoriteFromList(m);
                          },
                          child: Icon(
                            m.favorite ? Icons.favorite : Icons.favorite_border,
                            color: m.favorite ? Colors.red : null,
                          ),
                        ),
                        title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${m.type} • ${m.year} • ${m.duration} мин'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m)),
                          );
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final movie = await Navigator.push<Movie>(context, MaterialPageRoute(builder: (_) => const AddMovieScreen()));
          if (movie != null) {
            await _movieService.addMovie(movie);
          }
        },
      ),
    );
  }
}