// lib/services/movie_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';

class MovieService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Получаем UID текущего пользователя
  String? get _userId => _auth.currentUser?.uid;

  // --- ЧТЕНИЕ ГЛОБАЛЬНЫХ ФИЛЬМОВ (коллекция movies) ---
  // Возвращает только базовую информацию, без личных полей
  Stream<List<Movie>> getMovies() {
    return _firestore.collection('movies').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Movie.fromJson(data);
      }).toList();
    });
  }

  // --- ПОЛУЧЕНИЕ ГЛОБАЛЬНОГО ФИЛЬМА С ЛИЧНЫМИ ДАННЫМИ ПОЛЬЗОВАТЕЛЯ ---
  // Объединяет данные из глобальной коллекции и личной коллекции пользователя
  Future<Movie> getMovieWithPersonalData(String movieId) async {
    if (_userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    // Получаем глобальный фильм
    final globalDoc = await _firestore.collection('movies').doc(movieId).get();
    if (!globalDoc.exists) {
      throw Exception('Фильм не найден');
    }

    final globalData = globalDoc.data()!;
    globalData['id'] = globalDoc.id;
    globalData['movieId'] = globalDoc.id;

    // Получаем личные данные пользователя для этого фильма
    final personalDoc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('my_movies')
        .where('movieId', isEqualTo: movieId)
        .limit(1)
        .get();

    if (personalDoc.docs.isNotEmpty) {
      final personalData = personalDoc.docs.first.data();
      // Объединяем данные
      globalData.addAll({
        'rating': personalData['rating'],
        'review': personalData['review'],
        'note': personalData['note'],
        'favorite': personalData['favorite'] ?? false,
        'watched': personalData['watched'] ?? false,
        'wantToWatch': personalData['wantToWatch'] ?? false,
      });
    }

    return Movie.fromJson(globalData);
  }

  // --- ДОБАВЛЕНИЕ ФИЛЬМА В ЛИЧНУЮ КОЛЛЕКЦИЮ ПОЛЬЗОВАТЕЛЯ ---
  // Если movieId указан - добавляет ссылку на глобальный фильм
  // Если movieId null - добавляет полностью новый фильм (пользовательский)
  Future<String> addMovieToMyCollection(Movie movie) async {
    if (_userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final personalData = movie.toPersonalJson();
      personalData.remove('id'); // ID будет создан автоматически

      final ref = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('my_movies')
          .add(personalData);

      // Сохраняем ID документа
      await ref.update({'id': ref.id});

      print('Фильм сохранён в my_movies: ${ref.id}');
      return ref.id;
    } on FirebaseException catch (e) {
      print('Ошибка сохранения фильма: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Неизвестная ошибка при добавлении фильма: $e');
      rethrow;
    }
  }

  // --- ДОБАВЛЕНИЕ НОВОГО ФИЛЬМА (пользователь создаёт свой) ---
  Future<String> addMovie(Movie movie) async {
    if (_userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      // Добавляем в личную коллекцию (movieId будет null, так как это новый фильм)
      return await addMovieToMyCollection(movie);
    } catch (e) {
      rethrow;
    }
  }

  // --- ДОБАВЛЕНИЕ ГЛОБАЛЬНОГО ФИЛЬМА В ЛИЧНУЮ КОЛЛЕКЦИЮ ---
  // Добавляет ссылку на глобальный фильм в личную коллекцию пользователя
  Future<String> addGlobalMovieToMyCollection(String globalMovieId) async {
    if (_userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      // Проверяем, не добавлен ли уже этот фильм
      final existing = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('my_movies')
          .where('movieId', isEqualTo: globalMovieId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id; // Уже добавлен
      }

      // Получаем данные глобального фильма
      final globalDoc = await _firestore.collection('movies').doc(globalMovieId).get();
      if (!globalDoc.exists) {
        throw Exception('Глобальный фильм не найден');
      }

      // Создаём запись в личной коллекции
      // Храним только movieId (ссылку на глобальный фильм) и личные поля
      // Базовые данные (title, type, genre и т.д.) берутся из глобальной коллекции
      final personalData = {
        'movieId': globalMovieId,
        'rating': null,
        'review': null,
        'note': null,
        'favorite': false,
        'watched': false,
        'wantToWatch': false,
      };

      final ref = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('my_movies')
          .add(personalData);

      await ref.update({'id': ref.id});

      print('Глобальный фильм добавлен в my_movies: ${ref.id}');
      return ref.id;
    } on FirebaseException catch (e) {
      print('Ошибка добавления глобального фильма: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Неизвестная ошибка: $e');
      rethrow;
    }
  }

  // --- ОБНОВЛЕНИЕ ЛИЧНЫХ ДАННЫХ ФИЛЬМА ---
  Future<void> updateMovieNote(String myMovieId, Movie updatedMovie) async {
    if (_userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final userCollection = _firestore
          .collection('users')
          .doc(_userId)
          .collection('my_movies');

      // Возможная причина дубликатов: вызывающий код передаёт глобальный movieId
      // вместо ID документа в my_movies. В этом случае вызов .doc(movieId).set(...)
      // создаёт новый документ с ID равным globalId, но без поля 'movieId'.
      // Чтобы этого избежать, сначала проверим:
      // 1) существует ли документ с переданным ID (личная запись), если да — используем её;
      // 2) иначе попробуем найти запись, где поле 'movieId' == переданный ID (ссылка на глобальный фильм);
      // 3) если ничего не найдено — создаём корректную личную запись и сохраняем поле 'movieId'.

      DocumentReference docRef = userCollection.doc(myMovieId);
      final existingDoc = await docRef.get();
      if (!existingDoc.exists) {
        // Возможно, передан global movieId. Попробуем найти по полю movieId.
        final query = await userCollection
            .where('movieId', isEqualTo: myMovieId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          docRef = userCollection.doc(query.docs.first.id);
          print('Найдена личная запись по полю movieId, используем документ: ${docRef.id}');
        } else {
          // Не найдено — создаём корректную личную запись, указывая movieId
          final createData = <String, dynamic>{
            'movieId': myMovieId,
            'rating': null,
            'review': null,
            'note': null,
            'favorite': false,
            'watched': false,
            'wantToWatch': false,
          };
          final newRef = await userCollection.add(createData);
          await newRef.update({'id': newRef.id});
          docRef = newRef;
          print('Создана новая личная запись с movieId=$myMovieId, docId=${newRef.id}');
        }
      }

      // Обновляем только личные поля
      final updateData = {
        'rating': updatedMovie.rating,
        'review': updatedMovie.review,
        'note': updatedMovie.note,
        'favorite': updatedMovie.favorite,
        'watched': updatedMovie.watched,
        'wantToWatch': updatedMovie.wantToWatch,
      };

      // Используем set с merge для надежности
      await docRef.set(updateData, SetOptions(merge: true));
      print('Личные данные фильма обновлены: ${docRef.id}');
    } on FirebaseException catch (e) {
      print('Ошибка обновления: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Неизвестная ошибка при обновлении: $e');
      rethrow;
    }
  }

  // --- ПОЛУЧЕНИЕ ЛИЧНЫХ ФИЛЬМОВ ПОЛЬЗОВАТЕЛЯ ---
  Stream<List<Movie>> getMyMovies() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('my_movies')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            print('Личная коллекция пуста');
            return <Movie>[];
          }
          
          try {
            final movies = <Movie>[];
            
            // Собираем все movieId которые нужно загрузить
            final movieIdsToLoad = <String>{};
            final personalMoviesByMovieId = <String, Map<String, dynamic>>{};
            
            for (var doc in snapshot.docs) {
              final data = doc.data();
              if (data.isEmpty) continue;
              
              data['id'] = doc.id;
              final movieId = data['movieId'] as String?;
              
              if (movieId != null && movieId.isNotEmpty) {
                movieIdsToLoad.add(movieId);
                personalMoviesByMovieId[movieId] = data;
              } else {
                // Это пользовательский фильм, добавляем его сразу
                final movie = Movie.fromJson(data);
                movies.add(movie);
                print('✓ Пользовательский фильм: ${movie.title}');
              }
            }
            
            // Если есть глобальные фильмы — загружаем их ВСЕ сразу
            if (movieIdsToLoad.isNotEmpty) {
              try {
                final globalDocs = await _firestore
                    .collection('movies')
                    .where(FieldPath.documentId, whereIn: movieIdsToLoad.toList())
                    .get();
                
                for (var globalDoc in globalDocs.docs) {
                  final globalData = globalDoc.data();
                  final movieId = globalDoc.id;
                  
                  if (personalMoviesByMovieId.containsKey(movieId)) {
                    // Мержим глобальные и личные данные
                    final personalData = personalMoviesByMovieId[movieId]!;
                    globalData['id'] = personalData['id']; // ID из personal документа
                    globalData['movieId'] = movieId;
                    
                    // Добавляем личные данные
                    globalData['rating'] = personalData['rating'];
                    globalData['review'] = personalData['review'];
                    globalData['note'] = personalData['note'];
                    globalData['favorite'] = personalData['favorite'] ?? false;
                    globalData['watched'] = personalData['watched'] ?? false;
                    globalData['wantToWatch'] = personalData['wantToWatch'] ?? false;
                    
                    final movie = Movie.fromJson(globalData);
                    movies.add(movie);
                    print('✓ Глобальный фильм с личными данными: ${movie.title}');
                  }
                }
              } catch (e) {
                print('Ошибка загрузки глобальных фильмов: $e');
                // Если ошибка при загрузке глобальных, используем личные данные как есть
                for (var entry in personalMoviesByMovieId.entries) {
                  try {
                    final movie = Movie.fromJson(entry.value);
                    movies.add(movie);
                  } catch (parseError) {
                    print('Ошибка парсинга фильма ${entry.key}: $parseError');
                  }
                }
              }
            }
            
            return movies;
          } catch (e) {
            print('Ошибка обработки списка фильмов: $e');
            return <Movie>[];
          }
        });
  }

  // --- ПОЛУЧЕНИЕ ID ЛИЧНОЙ ЗАПИСИ ПО ГЛОБАЛЬНОМУ ID ---
  Future<String?> getMyMovieIdByGlobalId(String globalMovieId) async {
    if (_userId == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('my_movies')
        .where('movieId', isEqualTo: globalMovieId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  // --- УДАЛЕНИЕ ФИЛЬМА ИЗ ЛИЧНОЙ КОЛЛЕКЦИИ ---
  Future<void> removeMovieFromMyCollection(String myMovieId) async {
    if (_userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('my_movies')
          .doc(myMovieId)
          .delete();

      print('Фильм удалён из my_movies: $myMovieId');
    } on FirebaseException catch (e) {
      print('Ошибка удаления: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // --- ПОЛУЧЕНИЕ ВСЕХ ФИЛЬМОВ (ГЛОБАЛЬНЫЕ + ПОЛЬЗОВАТЕЛЬСКИЕ) ---
  // Объединяет фильмы из глобальной коллекции и пользовательские фильмы (без movieId)
  Stream<List<Movie>> getAllMovies() {
    if (_userId == null) {
      // Если пользователь не авторизован, возвращаем только глобальные
      return getMovies();
    }

    // Создаём контроллер для объединения двух потоков
    final controller = StreamController<List<Movie>>.broadcast();
    List<Movie> lastGlobalMovies = [];
    List<Movie> lastMyMovies = [];
    bool globalInitialized = false;

    void emitCombined() {
      // Показываем данные как только глобальные фильмы загрузились
      if (!globalInitialized) {
        print('⚠️ Ожидание загрузки глобальных фильмов...');
        return;
      }
      
      print('📊 emitCombined вызван:');
      print('   - Глобальных фильмов: ${lastGlobalMovies.length}');
      print('   - Личных записей: ${lastMyMovies.length}');
      
      // Создаём карту личных данных по movieId для быстрого поиска
      final personalDataMap = <String, Movie>{};
      int personalWithMovieId = 0;
      int personalWithoutMovieId = 0;
      
      // Подготовим быстрый набор глобальных ID для сопоставления
      final globalIds = lastGlobalMovies.map((m) => m.id).whereType<String>().toSet();

      for (var myMovie in lastMyMovies) {
        if (myMovie.movieId != null && myMovie.movieId!.isNotEmpty) {
          // Явная ссылка на глобальный фильм
          personalDataMap[myMovie.movieId!] = myMovie;
          personalWithMovieId++;
          print('   ✓ Личная запись для глобального фильма: ${myMovie.movieId}');
        } else if (myMovie.id != null && globalIds.contains(myMovie.id)) {
          // Существуют случаи, когда документ был создан с ID == globalId, но не имеет поля movieId
          // — это портит отображение (показывается пустой пользовательский фильм).
          // В таких случаях считаем запись ссылкой на глобальный фильм по doc.id
          personalDataMap[myMovie.id!] = myMovie;
          personalWithMovieId++;
          print('   ✓ Личная запись (по совпадению id==globalId): ${myMovie.id}');
        } else {
          personalWithoutMovieId++;
          print('   ✓ Пользовательский фильм (без movieId): ${myMovie.id} - ${myMovie.title}');
        }
      }
      
      print('   - С movieId (ссылки на глобальные): $personalWithMovieId');
      print('   - Без movieId (пользовательские): $personalWithoutMovieId');

      // Объединяем списки
      final allMovies = <String, Movie>{};
      
      // 1. Добавляем ВСЕ глобальные фильмы и объединяем с личными данными
      int globalWithPersonal = 0;
      int globalWithoutPersonal = 0;
      
      for (var globalMovie in lastGlobalMovies) {
        if (globalMovie.id == null) {
          print('   ⚠️ Глобальный фильм без ID пропущен');
          continue;
        }
        
        // Проверяем, есть ли личные данные для этого фильма
        if (personalDataMap.containsKey(globalMovie.id)) {
          // Объединяем глобальные данные с личными
          final personalMovie = personalDataMap[globalMovie.id!]!;
          final combinedMovie = Movie(
            id: personalMovie.id, // ID из личной коллекции (important!)
            movieId: globalMovie.id, // Сохраняем ссылку на глобальный фильм
            title: globalMovie.title,
            type: globalMovie.type,
            genre: globalMovie.genre,
            year: globalMovie.year,
            duration: globalMovie.duration,
            actors: globalMovie.actors,
            description: globalMovie.description,
            // Личные поля из my_movies
            rating: personalMovie.rating,
            review: personalMovie.review,
            note: personalMovie.note,
            favorite: personalMovie.favorite,
            watched: personalMovie.watched,
            wantToWatch: personalMovie.wantToWatch,
          );
          allMovies[globalMovie.id!] = combinedMovie;
          globalWithPersonal++;
          print('   ✓ Глобальный фильм "${globalMovie.title}" с личными данными');
        } else {
          // Нет личных данных, показываем только глобальный фильм
          allMovies[globalMovie.id!] = globalMovie;
          globalWithoutPersonal++;
        }
      }
      
      print('   - Глобальных с личными данными: $globalWithPersonal');
      print('   - Глобальных без личных данных: $globalWithoutPersonal');
      
      if (lastGlobalMovies.isEmpty) {
        print('⚠️ КРИТИЧЕСКОЕ ПРЕДУПРЕЖДЕНИЕ: Глобальные фильмы не загружены!');
        print('   Проверьте коллекцию "movies" в Firestore');
      }

      // 2. Добавляем пользовательские фильмы (созданные пользователем, без movieId)
      int userCreatedCount = 0;
      for (var myMovie in lastMyMovies) {
        if ((myMovie.movieId == null || myMovie.movieId!.isEmpty) && myMovie.id != null) {
          // Это пользовательский фильм (не из глобальной коллекции)
          // Используем уникальный ключ, чтобы не перезаписать глобальные
          final uniqueKey = 'user_${myMovie.id!}';
          allMovies[uniqueKey] = myMovie;
          userCreatedCount++;
          print('   ✓ Добавлен пользовательский фильм: ${myMovie.title} (ID: ${myMovie.id})');
        }
      }
      print('   - Пользовательских фильмов добавлено: $userCreatedCount');

      final result = allMovies.values.toList();
      print('✅ ИТОГО: Отправка ${result.length} фильмов в UI');
      print('   - Из них глобальных: ${globalWithPersonal + globalWithoutPersonal}');
      print('   - Из них пользовательских: $userCreatedCount');
      
      if (result.isEmpty) {
        print('⚠️ ВНИМАНИЕ: Список фильмов пуст!');
        print('   Проверьте:');
        print('   1. Есть ли документы в коллекции "movies"?');
        print('   2. Правильно ли настроены правила доступа Firestore?');
      } else if (globalWithPersonal + globalWithoutPersonal == 0 && userCreatedCount > 0) {
        print('⚠️ ПРОБЛЕМА: Показываются только пользовательские фильмы!');
        print('   Глобальные фильмы не загружены. Проверьте коллекцию "movies"');
      }
      controller.add(result);
    }

    // Слушаем глобальные фильмы
    final globalSubscription = getMovies().listen(
      (movies) {
        print('Получены глобальные фильмы: ${movies.length}');
        lastGlobalMovies = movies;
        globalInitialized = true;
        emitCombined();
      },
      onError: (error) {
        print('Ошибка загрузки глобальных фильмов: $error');
        // Инициализируем как пустой список при ошибке, чтобы не блокировать
        globalInitialized = true;
        lastGlobalMovies = [];
        emitCombined();
      },
      onDone: () {
        print('Поток глобальных фильмов завершён');
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    // Слушаем личные фильмы
    final mySubscription = getMyMovies().listen(
      (movies) {
        print('Получены личные фильмы: ${movies.length}');
        lastMyMovies = movies;
        emitCombined(); // Обновляем список когда личные фильмы загрузились
      },
      onError: (error) {
        print('Ошибка загрузки личных фильмов: $error');
        // Не прерываем поток, просто логируем ошибку и используем пустой список
        lastMyMovies = [];
        // (removed myInitialized flag) используем пустой список
        emitCombined();
      },
      cancelOnError: false, // Не отменяем подписку при ошибке
    );

    // Закрываем подписки при закрытии контроллера
    controller.onCancel = () {
      globalSubscription.cancel();
      mySubscription.cancel();
    };

    return controller.stream;
  }
}
