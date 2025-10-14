import 'package:hive/hive.dart';
import 'place.dart';

part 'region.g.dart';

@HiveType(typeId: 2)
class Region extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  String imageUrl;

  @HiveField(4)
  List<Place> places;

  Region({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.places,
  });

  // ---------- JSON ----------
  factory Region.fromJson(Map<String, dynamic> j) {
    List<Place> _parsePlaces(dynamic v) {
      if (v is List) {
        return v
            .where((e) => e is Map<String, dynamic>)
            .map<Place>((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <Place>[];
    }

    return Region(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      imageUrl: (j['imageUrl'] ?? '').toString(),
      // Если не планируешь хранить places во входном JSON — придёт пустой список, это ок
      places: _parsePlaces(j['places']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'places': places.map((p) => p.toJson()).toList(),
  };
}
