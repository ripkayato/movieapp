// lib/models/movie.dart
class Movie {
  final String? id; // ID документа в my_movies или movies
  final String? movieId; // ID фильма из глобальной коллекции (если есть)
  final String title;
  final String type; // 'Фильм' или 'Сериал'
  final String genre;
  final int year;
  final int duration; // в минутах
  final List<String> actors;
  final String description;
  // Личные поля (хранятся только в my_movies)
  int? rating; // 1-10
  String? review;
  String? note; // Дополнительная заметка
  bool favorite;
  bool watched;
  bool wantToWatch;

  Movie({
    this.id,
    this.movieId,
    required this.title,
    required this.type,
    required this.genre,
    required this.year,
    required this.duration,
    required this.actors,
    required this.description,
    this.rating,
    this.review,
    this.note,
    this.favorite = false,
    this.watched = false,
    this.wantToWatch = false,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: json['id'] as String?,
        movieId: json['movieId'] as String?,
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'Фильм',
        genre: json['genre'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        actors: json['actors'] != null 
            ? List<String>.from((json['actors'] as List).map((e) => e?.toString() ?? ''))
            : <String>[],
        description: json['description'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt(),
        review: json['review'] as String?,
        note: json['note'] as String?,
        favorite: json['favorite'] as bool? ?? false,
        watched: json['watched'] as bool? ?? false,
        wantToWatch: json['wantToWatch'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'movieId': movieId,
        'title': title,
        'type': type,
        'genre': genre,
        'year': year,
        'duration': duration,
        'actors': actors,
        'description': description,
        'rating': rating,
        'review': review,
        'note': note,
        'favorite': favorite,
        'watched': watched,
        'wantToWatch': wantToWatch,
      };

  // JSON только для глобальной коллекции (без личных полей)
  Map<String, dynamic> toGlobalJson() => {
        'id': id,
        'title': title,
        'type': type,
        'genre': genre,
        'year': year,
        'duration': duration,
        'actors': actors,
        'description': description,
      };

  // JSON только для личной коллекции (с личными полями)
  // ВАЖНО: для глобальных фильмов сохраняем только movieId и личные поля
  //        базовые поля (title, type, genre и т.д.) берутся из глобальной коллекции
  // Для пользовательских фильмов (movieId == null) сохраняем и базовые данные
  Map<String, dynamic> toPersonalJson() {
    final data = <String, dynamic>{
      'rating': rating,
      'review': review,
      'note': note,
      'favorite': favorite,
      'watched': watched,
      'wantToWatch': wantToWatch,
    };
    
    // Если это ссылка на глобальный фильм, добавляем movieId
    if (movieId != null && movieId!.isNotEmpty) {
      data['movieId'] = movieId;
    } else {
      // Если это пользовательский фильм, сохраняем и базовые данные
      data['title'] = title;
      data['type'] = type;
      data['genre'] = genre;
      data['year'] = year;
      data['duration'] = duration;
      data['actors'] = actors;
      data['description'] = description;
    }
    
    return data;
  }

  Movie copyWith({
    String? id,
    String? movieId,
    String? title,
    String? type,
    String? genre,
    int? year,
    int? duration,
    List<String>? actors,
    String? description,
    int? rating,
    String? review,
    String? note,
    bool? favorite,
    bool? watched,
    bool? wantToWatch,
  }) {
    return Movie(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      title: title ?? this.title,
      type: type ?? this.type,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      duration: duration ?? this.duration,
      actors: actors ?? this.actors,
      description: description ?? this.description,
      rating: rating,
      review: review,
      note: note,
      favorite: favorite ?? this.favorite,
      watched: watched ?? this.watched,
      wantToWatch: wantToWatch ?? this.wantToWatch,
    );
  }
}