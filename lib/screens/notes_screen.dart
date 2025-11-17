// lib/screens/notes_screen.dart
import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'movie_detail_screen.dart';

class NotesScreen extends StatelessWidget {
  final List<Movie> movies;
  final String title;

  const NotesScreen({super.key, required this.movies, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: movies.isEmpty
          ? const Center(child: Text('Пока пусто'))
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, i) {
                final m = movies[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: Icon(
                      m.favorite ? Icons.favorite : Icons.movie,
                      color: m.favorite ? Colors.red : null,
                    ),
                    title: Text(m.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${m.type} • ${m.year}'),
                        if (m.rating != null) Text('Оценка: ${m.rating}/10'),
                        if (m.review != null && m.review!.isNotEmpty)
                          Text(m.review!, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}