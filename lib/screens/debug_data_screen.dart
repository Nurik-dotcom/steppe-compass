
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/region.dart';
import '../models/place.dart';
import '../models/user.dart';

class DebugDataScreen extends StatefulWidget {
  const DebugDataScreen({Key? key}) : super(key: key);

  @override
  State<DebugDataScreen> createState() => _DebugDataScreenState();
}

class _DebugDataScreenState extends State<DebugDataScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  late final Box<Region> _regions;
  late final Box<Place> _places;
  late final Box<User> _users;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _regions = Hive.box<Region>('regions');
    _places  = Hive.box<Place>('places');
    _users   = Hive.box<User>('users');
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _dumpAll() {
    final dump = {
      'regions': _regions.toMap().entries.map((e) => {
        'hiveKey': e.key,
        'id': _safe(() => e.value.id),
        'name': _safe(() => e.value.name),
        'description': _safe(() => e.value.description),
        'imageUrl': _safe(() => e.value.imageUrl),
      }).toList(),
      'places': _places.toMap().entries.map((e) => {
        'hiveKey': e.key,
        'id': _safe(() => e.value.id),
        'name': _safe(() => e.value.name),
        'description': _safe(() => e.value.description),
        'regionId': _safe(() => e.value.regionId),
        'category': _safe(() => e.value.category),
        'imageUrl': _safe(() => e.value.imageUrl),
        'latitude': _safe(() => e.value.latitude),
        'longitude': _safe(() => e.value.longitude),
      }).toList(),
      'users': _users.toMap().entries.map((e) => {
        'hiveKey': e.key,
        'email': _safe(() => e.value.email),
        'isAdmin': _safe(() => e.value.isAdmin),
      }).toList(),
    };
    debugPrint(const JsonEncoder.withIndent('  ').convert(dump));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дамп отправлен в консоль')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Data Viewer'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Regions'),
            Tab(text: 'Places'),
            Tab(text: 'Users'),
          ],
        ),
        actions: [
          IconButton(onPressed: _dumpAll, icon: const Icon(Icons.terminal)),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _BoxList<Region>(box: _regions, itemBuilder: (key, r) => ListTile(
            leading: const Icon(Icons.map),
            title: Text(r.name ?? '—'),
            subtitle: Text('hiveKey=$key | id=${r.id}'),
          )),
          _BoxList<Place>(box: _places, itemBuilder: (key, p) => ListTile(
            leading: const Icon(Icons.place),
            title: Text(p.name ?? '—'),
            subtitle: Text('hiveKey=$key | id=${p.id} | regionId=${p.regionId}'),
          )),
          _BoxList<User>(box: _users, itemBuilder: (key, u) => ListTile(
            leading: const Icon(Icons.person),
            title: Text(u.email ?? '—'),
            subtitle: Text('hiveKey=$key | isAdmin=${u.isAdmin == true}'),
          )),
        ],
      ),
    );
  }
}

class _BoxList<T> extends StatelessWidget {
  final Box<T> box;
  final Widget Function(dynamic hiveKey, T value) itemBuilder;
  const _BoxList({Key? key, required this.box, required this.itemBuilder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, _, __) {
        final entries = box.toMap().entries.toList();
        if (entries.isEmpty) {
          return const Center(child: Text('Пусто'));
        }
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = entries[i];
            return itemBuilder(e.key, e.value);
          },
        );
      },
    );
  }
}

dynamic _safe(Function f) {
  try { return f(); } catch (_) { return null; }
}
