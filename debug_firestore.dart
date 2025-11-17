// Скрипт для debug проверки структуры Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  // Логинься перед запуском
  if (auth.currentUser == null) {
    print('❌ Пользователь не авторизован');
    return;
  }
  
  final userId = auth.currentUser!.uid;
  print('👤 Пользователь: $userId\n');
  
  // Проверяем глобальные фильмы
  print('=== ГЛОБАЛЬНЫЕ ФИЛЬМЫ ===');
  final globalMovies = await firestore.collection('movies').limit(3).get();
  for (final doc in globalMovies.docs) {
    print('\n📽️ ID: ${doc.id}');
    print('   Данные: ${doc.data()}');
  }
  
  // Проверяем личные фильмы
  print('\n\n=== ЛИЧНЫЕ ФИЛЬМЫ ПОЛЬЗОВАТЕЛЯ ===');
  final myMovies = await firestore
      .collection('users')
      .doc(userId)
      .collection('my_movies')
      .limit(5)
      .get();
  
  for (final doc in myMovies.docs) {
    print('\n📖 ID: ${doc.id}');
    final data = doc.data();
    print('   movieId: ${data['movieId']}');
    print('   title: ${data['title']}');
    print('   favorite: ${data['favorite']}');
    print('   rating: ${data['rating']}');
    print('   Все поля: $data');
  }
  
  print('\n✅ Готово');
}
