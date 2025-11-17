// lib/services/push_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PushService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    if (kIsWeb) return;

    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (kDebugMode) print('FCM Token: $token');

    final user = FirebaseAuth.instance.currentUser;
    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) print('Push: ${message.notification?.title}');
    });
  }

  void subscribeToNewMovies() {
    if (kIsWeb) return;
    _messaging.subscribeToTopic('new_movies');
  }
}