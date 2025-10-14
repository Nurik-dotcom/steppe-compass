import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

class FavoritesService {
  static const _boxName = 'favorites'; 

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static String _userKey(String userId) => 'fav_$userId';

  static Set<String> _getSet(String userId) {
    final key = _userKey(userId);
    final raw = _box.get(key);
    if (raw is List) return raw.cast<String>().toSet(); 
    if (raw is Set) return raw.cast<String>();
    return <String>{};
  }

  static bool isFavorite(String userId, String placeId) {
    return _getSet(userId).contains(placeId);
  }

  static Future<void> toggle(String userId, String placeId) async {
    final key = _userKey(userId);
    final favs = _getSet(userId);
    if (favs.contains(placeId)) {
      favs.remove(placeId);
    } else {
      favs.add(placeId);
    }
    await _box.put(key, favs.toList()); 
  }

  static List<String> all(String userId) => _getSet(userId).toList();

  static ValueListenable listenable(String userId) => _box.listenable(keys: [_userKey(userId)]);
}
