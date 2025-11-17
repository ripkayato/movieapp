// migrate_movies.js
const admin = require('firebase-admin');

// Вставь свои данные из Firebase Console → Project Settings → Service Accounts → Generate new private key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrate() {
  console.log('Запуск миграции...');

  const moviesSnap = await db.collection('movies').get();
  const usersSnap = await db.collection('users').get();

  // 1. Очищаем личные поля из movies
  const batchClear = db.batch();
  for (const doc of moviesSnap.docs) {
    const data = doc.data();
    const hasPersonal = ['rating', 'review', 'favorite', 'watched', 'wantToWatch'].some(field => field in data);
    if (hasPersonal) {
      const cleanData = { ...data };
      delete cleanData.rating;
      delete cleanData.review;
      delete cleanData.favorite;
      delete cleanData.watched;
      delete cleanData.wantToWatch;
      batchClear.set(doc.ref, cleanData, { merge: true });
    }
  }
  await batchClear.commit();
  console.log(`Очищено ${moviesSnap.size} фильмов`);

  // 2. Переносим личные заметки в my_movies
  const batchMove = db.batch();
  let movedCount = 0;

  for (const userDoc of usersSnap.docs) {
    const uid = userDoc.id;
    const userData = userDoc.data();

    // Проверяем, есть ли в users/{uid} поле movies (если раньше хранилось там)
    if (userData.movies && Array.isArray(userData.movies)) {
      for (const movie of userData.movies) {
        if (movie.id) {
          const noteRef = db.collection('users').doc(uid).collection('my_movies').doc(movie.id);
          batchMove.set(noteRef, {
            rating: movie.rating ?? null,
            review: movie.review ?? '',
            favorite: movie.favorite ?? false,
            watched: movie.watched ?? false,
            wantToWatch: movie.wantToWatch ?? false,
          }, { merge: true });
          movedCount++;
        }
      }
      // Удаляем старое поле movies из users/{uid}
      batchMove.update(userDoc.ref, { movies: admin.firestore.FieldValue.delete() });
    }
  }

  // 3. Если заметки были в movies (редко, но вдруг)
  for (const movieDoc of moviesSnap.docs) {
    const data = movieDoc.data();
    const movieId = movieDoc.id;

    if (data.rating != null || data.review != null || data.favorite != null) {
      for (const userDoc of usersSnap.docs) {
        const uid = userDoc.id;
        const noteRef = db.collection('users').doc(uid).collection('my_movies').doc(movieId);
        batchMove.set(noteRef, {
          rating: data.rating,
          review: data.review ?? '',
          favorite: data.favorite ?? false,
          watched: data.watched ?? false,
          wantToWatch: data.wantToWatch ?? false,
        }, { merge: true });
        movedCount++;
      }
    }
  }

  await batchMove.commit();
  console.log(`Перенесено ${movedCount} заметок в my_movies`);

  console.log('Миграция завершена!');
  process.exit(0);
}

migrate().catch(err => {
  console.error('Ошибка:', err);
  process.exit(1);
});