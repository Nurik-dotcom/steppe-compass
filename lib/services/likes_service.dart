import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class LikesService {



  static const _likesBox = 'likes';
  static const _userLikesBox = 'user_likes';


  static Future<void> init() async {
    await Hive.openBox<int>(_likesBox);
    await Hive.openBox(_userLikesBox);
  }

  static Box<int> get _likes => Hive.box<int>(_likesBox);
  static Box get _userLikes => Hive.box(_userLikesBox);


  static int count(String placeId) => _likes.get(placeId, defaultValue: 0)!;

  static bool hasLiked(String userId, String placeId) {
    final key = 'ul_$userId';
    final raw = _userLikes.get(key);
    if (raw is List) return raw.cast<String>().toSet().contains(placeId);
    if (raw is Set) return raw.cast<String>().contains(placeId);
    return false;

  }

  static Future<void> like(String userId, String placeId) async {
    if (hasLiked(userId, placeId)) return;

    final c = count(placeId) + 1;
    await _likes.put(placeId, c);

    final key = 'ul_$userId';
    final raw = _userLikes.get(key);
    final set = (raw is List ? raw.cast<String>().toSet()
        : raw is Set ? raw.cast<String>()
        : <String>{});
    set.add(placeId);
    await _userLikes.put(key, set.toList());
  }

  static Future<void> unlike(String userId, String placeId) async {
    if (!hasLiked(userId, placeId)) return;

    final dec = count(placeId) - 1;
    final c = dec < 0 ? 0 : dec;
    await _likes.put(placeId, c);

    final key = 'ul_$userId';
    final raw = _userLikes.get(key);
    final set = (raw is List ? raw.cast<String>().toSet()
        : raw is Set ? raw.cast<String>()
        : <String>{});
    set.remove(placeId);
    await _userLikes.put(key, set.toList());
  }

  static ValueListenable<Box<int>> likesListenable([List<String>? placeIds]) =>
      _likes.listenable(keys: placeIds);

  static Map<String, int> topLikes(Iterable<String> placeIds) {
    final out = <String, int>{};
    for (final id in placeIds) {
      out[id] = count(id);
    }
    return out;
  }


  int getLikesCount(String placeId) => LikesService.count(placeId);
  ValueListenable<Box<int>> listenable([List<String>? placeIds]) =>
      LikesService.likesListenable(placeIds);

  static void toggle(String userId, String id) {}
}

class LikesServiceRemote {
  LikesServiceRemote({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('User is not authenticated');
    }
    return u.uid;
  }

  String _docId(String placeId) => '${_uid}_$placeId';

  // 🔥 Тоггл лайка + обновление likesCount в коллекции "place"
  Future<void> toggleLike(String placeId) async {
    final likeRef = _db.collection('likes').doc(_docId(placeId));
    final placeRef = _db.collection('place').doc(placeId); // имя коллекции как в Firestore

    await _db.runTransaction((tx) async {
      final snap = await tx.get(likeRef);
      if (snap.exists) {
        // убираем лайк
        tx.delete(likeRef);
        tx.update(placeRef, {
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // ставим лайк
        tx.set(likeRef, {
          'uid': _uid,
          'placeId': placeId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(placeRef, {
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  Stream<bool> isLikedStream(String placeId) {
    return _db.collection('likes').doc(_docId(placeId))
        .snapshots().map((d) => d.exists);
  }

  Stream<int> likeCountStream(String placeId) {
    return _db.collection('likes')
        .where('placeId', isEqualTo: placeId)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<bool> isLiked(String placeId) async {
    final d = await _db.collection('likes').doc(_docId(placeId)).get();
    return d.exists;
  }
}
