// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyNewMovie = functions.firestore
  .document('movies/{movieId}')
  .onCreate(async (snap) => {
    const movie = snap.data();
    const payload = {
      notification: {
        title: 'Новый фильм в базе!',
        body: movie.title,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };
    await admin.messaging().sendToTopic('new_movies', payload);
  });