// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> likeMovie(String movieId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('likes')
        .doc(movieId)
        .set({'likedAt': FieldValue.serverTimestamp()});
  }

  Future<void> unlikeMovie(String movieId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('likes').doc(movieId).delete();
  }

  Stream<List<String>> getLikedMovies() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('likes')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }
}