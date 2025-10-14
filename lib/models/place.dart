import 'package:hive/hive.dart';
part 'place.g.dart';

@HiveType(typeId: 1)
class Place {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<String> imageUrl; // список URL изображений

  @HiveField(4)
  final double? latitude;

  @HiveField(5)
  final double? longitude;

  @HiveField(6)
  final List<String> categories;

  @HiveField(7)
  final List<String> subcategories;

  @HiveField(8)
  final String workingHours;

  @HiveField(9)
  final String ticketPrice;

  @HiveField(10)
  final String address;

  @HiveField(11)
  final String regionId;

  @HiveField(12)
  String? videoUrl;

  Place ({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    required this.categories,
    required this.subcategories,
    required this.workingHours,
    required this.ticketPrice,
    required this.address,
    this.videoUrl,
    required this.regionId,
  });

  // Сохраняем как есть (если где-то используется)
  get category => null;

  // ---------- JSON ----------
  factory Place.fromJson(Map<String, dynamic> j) {
    List<String> _stringsFrom(dynamic v) {
      if (v == null) return <String>[];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [v.toString()];
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Place(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      imageUrl: _stringsFrom(j['imageUrl']),
      latitude: _toDouble(j['latitude']),
      longitude: _toDouble(j['longitude']),
      categories: _stringsFrom(j['categories']),
      subcategories: _stringsFrom(j['subcategories']),
      workingHours: (j['workingHours'] ?? '').toString(),
      ticketPrice: (j['ticketPrice'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      videoUrl: j['videoUrl']?.toString(),
      regionId: (j['regionId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'latitude': latitude,
    'longitude': longitude,
    'categories': categories,
    'subcategories': subcategories,
    'workingHours': workingHours,
    'ticketPrice': ticketPrice,
    'address': address,
    'videoUrl': videoUrl,
    'regionId': regionId,
  };
}
