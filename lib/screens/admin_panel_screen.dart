import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/region.dart';
import '../models/place.dart';
import 'edit_region_screen.dart';
import 'edit_place_screen.dart';
import '../utils/place_categories.dart';
import '../services/json_import_service.dart';
import '../widgets/json_import_preview_dialog.dart';
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}
class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String currentSection = 'region';

  final Box<Region> regionBox = Hive.box<Region>('regions');
  final Box<Place> placeBox = Hive.box<Place>('places');

  String? selectedRegionIdFilter;
  String? selectedSubcategoryFilter;

  void _deleteRegion(String id) {
    regionBox.delete(id);
    setState(() {});
  }

  void _deletePlace(String id) {
    placeBox.delete(id);
    setState(() {});
  }

  Future<void> _openAdd() async {
    if (currentSection == 'region') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditRegionScreen()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditPlaceScreen()),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final regionsList = regionBox.values.toList();
    final placesList = placeBox.values.toList();

    final filteredPlaces = placesList.where((place) {
      final matchesRegion = selectedRegionIdFilter == null || place.regionId == selectedRegionIdFilter;
      final matchesSubcategory = selectedSubcategoryFilter == null || place.subcategories.contains(selectedSubcategoryFilter!);
      return matchesRegion && matchesSubcategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          
          IconButton(
            tooltip: currentSection == 'region' ? 'Добавить регион' : 'Добавить место',
            icon: const Icon(Icons.add),
            onPressed: _openAdd,
          ),
          PopupMenuButton<String>(
            tooltip: 'Импорт из JSON',
            onSelected: (value) async {
              if (value == 'regions') {
                final raw = await pickAndDecodeJson(context);
                if (raw.isEmpty) return;
                final items = parseRegions(raw);
                
                
                
                await showDialog(
                  context: context,
                  builder: (_) => JsonImportPreviewDialog<Region>(
                    title: 'Импорт регионов (${items.length})',
                    items: items,
                    primary: (r) => r.name ?? '—',
                    secondary: (r) => 'id=${r.id ?? '—'}  |  ${r.description ?? ''}',
                    onImport: (selected, overwrite) async {
                      final c = await importRegions(regions: selected, overwriteIfExists: overwrite);
                      setState(() {}); 
                      return c;
                    },
                  ),
                );
              } else if (value == 'places') {
                final raw = await pickAndDecodeJson(context);
                if (raw.isEmpty) return;
                final items = parsePlaces(raw);
                
                await showDialog(
                  context: context,
                  builder: (_) => JsonImportPreviewDialog<Place>(
                    title: 'Импорт мест (${items.length})',
                    items: items,
                    primary: (p) => p.name ?? '—',
                    secondary: (p) => 'id=${p.id ?? '—'}  •  regionId=${p.regionId ?? '—'}  •  ${p.category ?? ''}',
                    onImport: (selected, overwrite) async {
                      final c = await importPlaces(places: selected, overwriteIfExists: overwrite);
                      setState(() {}); 
                      return c;
                    },
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'regions', child: Text('Импорт регионов (JSON)')),
              PopupMenuItem(value: 'places',  child: Text('Импорт мест (JSON)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          ToggleButtons(
            isSelected: [
              currentSection == 'region',
              currentSection == 'place',
            ],
            onPressed: (idx) {
              setState(() {
                currentSection = idx == 0 ? 'region' : 'place';
                selectedRegionIdFilter = null;
                selectedSubcategoryFilter = null;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Регионы'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Места'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: currentSection == 'region'
                ? ListView.builder(
              itemCount: regionsList.length,
              itemBuilder: (context, i) {
                final r = regionsList[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    radius: 24,
                    child: ClipOval(
                      child: r.imageUrl.startsWith('http')
                          ? Image.network(
                        r.imageUrl,
                        width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      )
                          : Image.asset(r.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                    ),
                  ),
                  title: Text(r.name),
                  subtitle: Text(r.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditRegionScreen(region: r)),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteRegion(r.id),
                      ),
                    ],
                  ),
                );
              },
            )
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedRegionIdFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Регион',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Все регионы'),
                          items: regionsList.map((r) {
                            return DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => selectedRegionIdFilter = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSubcategoryFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Подкатегория',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Все подкатегории'),
                          items: subcategories.map((sub) {
                            return DropdownMenuItem(
                              value: sub,
                              child: Text(sub),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => selectedSubcategoryFilter = v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Сбросить фильтры',
                        onPressed: () {
                          setState(() {
                            selectedRegionIdFilter = null;
                            selectedSubcategoryFilter = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredPlaces.length,
                    itemBuilder: (context, i) {
                      final p = filteredPlaces[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          radius: 24,
                          child: p.imageUrl.isNotEmpty
                              ? ClipOval(
                            child: p.imageUrl.first.startsWith('http')
                                ? Image.network(
                              p.imageUrl.first,
                              width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            )
                                : Image.asset(p.imageUrl.first, width: 48, height: 48, fit: BoxFit.cover),
                          )
                              : const Icon(Icons.photo),
                        ),
                        title: Text(p.name),
                        subtitle: Text('Подкатегории: ${p.subcategories.join(', ')}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditPlaceScreen(existing: p)),
                                ).then((_) => setState(() {}));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deletePlace(p.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      
    );
  }
}
