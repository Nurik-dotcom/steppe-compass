import 'package:hive/hive.dart';
import '../models/region.dart';

class RegionService {
  static final Box<Region> _box = Hive.box<Region>('regions');

  static List<Region> getAll() => _box.values.toList();

  static Future<void> add(Region region) => _box.put(region.id, region);

  static Future<void> update(Region region) => _box.put(region.id, region);

  static Future<void> delete(String id) => _box.delete(id);
}
