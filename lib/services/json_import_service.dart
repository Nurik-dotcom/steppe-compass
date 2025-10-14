import 'dart:convert';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/region.dart';
import '../models/place.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import '../models/region.dart';
import '../models/place.dart';
final _uuid = const Uuid();



Future<List<Map<String, dynamic>>> pickAndDecodeJson(BuildContext context) async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (res == null || res.files.isEmpty) return [];

  Uint8List? bytes = res.files.single.bytes;
  if (bytes == null && res.files.single.path != null) {

    bytes = await File(res.files.single.path!).readAsBytes();
  }
  if (bytes == null) return [];

  final text = utf8.decode(bytes);
  final dynamic parsed = jsonDecode(text);

  if (parsed is List) {
    return parsed
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => e.cast<String, dynamic>())
        .toList();
  } else if (parsed is Map) {
    return [parsed.cast<String, dynamic>()];
  } else {
    return [];
  }
}


List<Region> parseRegions(List<Map<String, dynamic>> items) =>
    items.map((m) => Region.fromJson(m)).toList();

List<Place> parsePlaces(List<Map<String, dynamic>> items) =>
    items.map((m) => Place.fromJson(m)).toList();

String _normalizeId(String raw) {
  final t = raw.trim();
  return t.isEmpty ? _uuid.v4() : t;
}


Place _withIdPlace(Place p, String id) {
  return Place(
    id: id,
    name: p.name,
    description: p.description,
    imageUrl: p.imageUrl,
    latitude: p.latitude,
    longitude: p.longitude,
    categories: p.categories,
    subcategories: p.subcategories,
    workingHours: p.workingHours,
    ticketPrice: p.ticketPrice,
    address: p.address,
    videoUrl: p.videoUrl,
    regionId: p.regionId,
  );
}


Region _withIdRegion(Region r, String id) {
  return Region(
    id: id,
    name: r.name,
    description: r.description,
    imageUrl: r.imageUrl,
    places: r.places,
  );
}



Future<int> importRegions({
  required List<Region> regions,
  required bool overwriteIfExists,
}) async {
  final box = Hive.box<Region>('regions');
  int imported = 0;

  for (final r in regions) {
    final id = _normalizeId(r.id);
    final normalized = (r.id == id) ? r : _withIdRegion(r, id);

    if (box.containsKey(id) && !overwriteIfExists) {

      continue;
    }

    await box.put(id, normalized);
    imported++;
  }
  return imported;
}

Future<int> importPlaces({
  required List<Place> places,
  required bool overwriteIfExists,
}) async {
  final box = Hive.box<Place>('places');
  int imported = 0;

  for (final p in places) {
    final id = _normalizeId(p.id);
    final normalized = (p.id == id) ? p : _withIdPlace(p, id);

    if (box.containsKey(id) && !overwriteIfExists) {
      continue;
    }

    await box.put(id, normalized);
    imported++;
  }
  return imported;
}


// lib/services/json_seed_service.dart  (или json_import_service.dart — как у тебя в проекте)

// ▼▼▼ ИЗМЕНЕНИЕ: Увеличили версию, чтобы заставить сервис перезаписать данные ▼▼▼
const int kSeedVersion = 7;


const String kBoxRegions = 'regions';
const String kBoxPlaces  = 'places';
const String kBoxMeta    = 'app_meta';

class JsonSeedService {
  Future<void> seedIfNeeded({void Function(String)? onLog}) async {
    final meta = await _ensureBox<dynamic>(kBoxMeta);
    final current = meta.get('seedVersion') as int?;

    // Принудительно очищаем боксы перед сидированием, если версия изменилась
    if (current != kSeedVersion) {
      onLog?.call('[seed] Новая версия! Очистка старых данных...');
      await Hive.box<Region>(kBoxRegions).clear();
      await Hive.box<Place>(kBoxPlaces).clear();
    }

    final regionsBox = await _ensureBox<Region>(kBoxRegions);
    final placesBox  = await _ensureBox<Place>(kBoxPlaces);

    final needSeed = current != kSeedVersion || regionsBox.isEmpty || placesBox.isEmpty;
    if (!needSeed) {
      onLog?.call('[seed] пропуск — актуально (v$current)');
      return;
    }

    onLog?.call('[seed] старт сидирования (v$kSeedVersion)…');

    // Regions
    final regionsRaw  = await rootBundle.loadString('assets/seeds/regions.json');
    final regionsList = (jsonDecode(regionsRaw) as List).cast<Map<String, dynamic>>();
    await regionsBox.putAll({
      for (final m in regionsList) _safeId(m['id']): Region.fromJson(m),
    });
    onLog?.call('[seed] regions: ${regionsList.length}');

    // Places
    final placesRaw  = await rootBundle.loadString('assets/seeds/places.json');
    final placesList = (jsonDecode(placesRaw) as List).cast<Map<String, dynamic>>();
    final toPut = <String, Place>{};
    for (final m in placesList) {
      final p = Place.fromJson(m);
      if ((p.regionId ?? '').isEmpty) continue;
      toPut[_safeId(p.id)] = p;
    }
    await placesBox.putAll(toPut);
    onLog?.call('[seed] places: ${toPut.length}');

    await meta.put('seedVersion', kSeedVersion);
    onLog?.call('[seed] завершено (v$kSeedVersion)');
  }

  Future<Box<T>> _ensureBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }

  String _safeId(dynamic v) {
    final s = (v ?? '').toString();
    return s.length <= 255 ? s : s.substring(0, 255);
  }
}
