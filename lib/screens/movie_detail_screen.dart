// lib/screens/movie_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _ms = MovieService();
  late Movie _movie;
  String? _myMovieId; // ID записи в личной коллекции
  bool _loading = true;
  bool _saving = false;
  final _reviewController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _reviewController.text = _movie.review ?? '';
    _noteController.text = _movie.note ?? '';
    _loadPersonalData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Загружаем личные данные для фильма
  Future<void> _loadPersonalData() async {
    setState(() => _loading = true);

    try {
      // Если это пользовательский фильм (movieId == null, но есть id)
      if (_movie.movieId == null && _movie.id != null && mounted) {
        // Это фильм из личной коллекции, используем его ID напрямую
        _myMovieId = _movie.id;
      } 
      // Если это глобальный фильм (есть movieId)
      else if (_movie.movieId != null && mounted) {
        final globalMovieId = _movie.movieId!;
        _myMovieId = await _ms.getMyMovieIdByGlobalId(globalMovieId);
        
        if (_myMovieId != null && mounted) {
          // Загружаем полные данные с личными полями
          try {
            final fullMovie = await _ms.getMovieWithPersonalData(globalMovieId);
            if (mounted) {
              setState(() {
                _movie = fullMovie;
                _reviewController.text = fullMovie.review ?? '';
                _noteController.text = fullMovie.note ?? '';
              });
            }
          } catch (e) {
            print('Ошибка загрузки личных данных: $e');
          }
        }
      }
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (!mounted) return;
    
    // Сохраняем предыдущее значение для отката при ошибке
    final previousFavorite = _movie.favorite;
    final newFavorite = !_movie.favorite;
    
    setState(() {
      _movie = _movie.copyWith(favorite: newFavorite);
    });

    try {
      // Если фильм еще не в личной коллекции, добавляем его
      if (_myMovieId == null) {
        final globalMovieId = _movie.movieId ?? _movie.id;
        if (globalMovieId != null) {
          // Это глобальный фильм, добавляем в личную коллекцию
          _myMovieId = await _ms.addGlobalMovieToMyCollection(globalMovieId);
          
          // После добавления проверяем, что документ создан, и обновляем favorite
          if (_myMovieId != null && mounted) {
            // Используем set с merge вместо update для надежности
            // Это создаст документ, если его нет, или обновит, если есть
            await _ms.updateMovieNote(_myMovieId!, _movie);
          }
        } else {
          // Это пользовательский фильм, должен быть в коллекции
          throw Exception('Фильм не найден в личной коллекции');
        }
      } else {
        // Фильм уже в коллекции, просто обновляем
        await _ms.updateMovieNote(_myMovieId!, _movie);
      }
    } catch (e) {
      // Откатываем при ошибке
      if (mounted) {
        setState(() {
          _movie = _movie.copyWith(favorite: previousFavorite);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_saving || !mounted) return;

    setState(() => _saving = true);

    try {
      // Обновляем модель с текущими значениями
      final updatedMovie = _movie.copyWith(
        review: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      // Если фильм ещё не в личной коллекции, добавляем его
      if (_myMovieId == null) {
        final globalMovieId = _movie.movieId ?? _movie.id;
        if (globalMovieId != null) {
          // Это глобальный фильм, добавляем в личную коллекцию
          _myMovieId = await _ms.addGlobalMovieToMyCollection(globalMovieId);
        } else {
          // Это новый фильм пользователя, уже должен быть в коллекции
          throw Exception('Фильм не найден в личной коллекции');
        }
      }

      // Обновляем личные данные
      await _ms.updateMovieNote(_myMovieId!, updatedMovie);

      if (mounted) {
        setState(() {
          _movie = updatedMovie;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заметка сохранена!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_movie.title, style: const TextStyle(fontSize: 18)),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: Icon(
                    _movie.favorite ? Icons.favorite : Icons.favorite_border,
                    color: _movie.favorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 250,
                      height: 370,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.movie, size: 80, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(_movie.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${_movie.type} • ${_movie.genre} • ${_movie.year} • ${_movie.duration} мин',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text('Актеры: ${_movie.actors.join(', ')}', style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 20),

                  const Text('Описание', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  Text(_movie.description, style: TextStyle(color: Colors.grey[300], height: 1.5)),
                  const SizedBox(height: 30),

                  // Оценка
                  const Text('Моя оценка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(10, (i) => IconButton(
                      icon: Icon(
                        i < (_movie.rating ?? 0) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => _movie = _movie.copyWith(rating: i + 1)),
                    )),
                  ),
                  const SizedBox(height: 20),

                  // Отзыв
                  const Text('Отзыв', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ваши впечатления...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Заметка
                  const Text('Заметка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Дополнительная заметка...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Статусы
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statusButton(Icons.check_circle, _movie.watched, Colors.green, () {
                        setState(() => _movie = _movie.copyWith(watched: !_movie.watched));
                      }),
                      _statusButton(Icons.visibility, _movie.wantToWatch, Colors.blue, () {
                        setState(() => _movie = _movie.copyWith(wantToWatch: !_movie.wantToWatch));
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Сохранить
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Сохранение...' : 'Сохранить заметку'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saving ? null : _saveNote,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statusButton(IconData icon, bool active, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 40, color: active ? color : Colors.grey),
          Text(active ? 'Да' : 'Нет', style: TextStyle(color: active ? color : Colors.grey)),
        ],
      ),
    );
  }
}
