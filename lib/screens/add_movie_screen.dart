// lib/screens/add_movie_screen.dart
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _titleController = TextEditingController();
  final _genreController = TextEditingController();
  final _yearController = TextEditingController();
  final _durationController = TextEditingController();
  final _actorsController = TextEditingController();
  final _descriptionController = TextEditingController();
  String type = 'Фильм';

  final _movieService = MovieService();

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _durationController.dispose();
    _actorsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить фильм/сериал'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Тип
            DropdownButton<String>(
              value: type,
              dropdownColor: Theme.of(context).scaffoldBackgroundColor,
              style: Theme.of(context).textTheme.bodyLarge,
              items: ['Фильм', 'Сериал']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => type = v ?? 'Фильм'),
            ),
            const SizedBox(height: 8),

            // Название
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Название',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Жанр
            TextField(
              controller: _genreController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Жанр',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Год
            TextField(
              controller: _yearController,
              style: Theme.of(context).textTheme.bodyLarge,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Год',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Длительность
            TextField(
              controller: _durationController,
              style: Theme.of(context).textTheme.bodyLarge,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Длительность (мин)',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Актеры
            TextField(
              controller: _actorsController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Актеры (через запятую)',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Описание
            TextField(
              controller: _descriptionController,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Описание',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка "Добавить"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                // Валидация
                if (_titleController.text.trim().isEmpty ||
                    _genreController.text.trim().isEmpty ||
                    _yearController.text.trim().isEmpty ||
                    _durationController.text.trim().isEmpty ||
                    _actorsController.text.trim().isEmpty ||
                    _descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Заполните все поля'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final year = int.tryParse(_yearController.text) ?? 2000;
                final duration = int.tryParse(_durationController.text) ?? 90;

                if (year < 1800 || year > DateTime.now().year + 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Некорректный год'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (duration <= 0 || duration > 600) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Длительность: 1–600 мин'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final movie = Movie(
                  title: _titleController.text.trim(),
                  type: type,
                  genre: _genreController.text.trim(),
                  year: year,
                  duration: duration,
                  actors: _actorsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  description: _descriptionController.text.trim(),
                );

                // Показываем индикатор
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Сохранение...'),
                      ],
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );

                try {
                  await _movieService.addMovie(movie);

                  if (mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Фильм успешно добавлен!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Добавить',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}