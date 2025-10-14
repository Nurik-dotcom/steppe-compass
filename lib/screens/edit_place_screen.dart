import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/place.dart';
import '../models/region.dart';


class EditPlaceScreen extends StatefulWidget {
  const EditPlaceScreen({Key? key, this.existing}) : super(key: key);

  final Place? existing;

  @override
  State<EditPlaceScreen> createState() => _EditPlaceScreenState();
}

class _EditPlaceScreenState extends State<EditPlaceScreen> {
  final _formKey = GlobalKey<FormState>();


  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imagesCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _workingHoursCtrl;
  late final TextEditingController _ticketPriceCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _categoriesCtrl;
  late final TextEditingController _subcategoriesCtrl;
  late final TextEditingController _videoUrlCtrl;


  String? _selectedRegionId;


  late final Future<void> _initFuture;
  late Box<Place> _placesBox;
  late Box<Region> _regionsBox;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _imagesCtrl = TextEditingController(
      text: (widget.existing?.imageUrl ?? const <String>[]) .join('\n'),
    );
    _latCtrl = TextEditingController(
      text: widget.existing?.latitude == null ? '' : '${widget.existing!.latitude}',
    );
    _lngCtrl = TextEditingController(
      text: widget.existing?.longitude == null ? '' : '${widget.existing!.longitude}',
    );
    _workingHoursCtrl = TextEditingController(text: widget.existing?.workingHours ?? '');
    _ticketPriceCtrl = TextEditingController(text: widget.existing?.ticketPrice ?? '');
    _addressCtrl = TextEditingController(text: widget.existing?.address ?? '');
    _categoriesCtrl = TextEditingController(
      text: (widget.existing?.categories ?? const <String>[])
          .join(', '),
    );

    _subcategoriesCtrl = TextEditingController(
      text: (widget.existing?.subcategories ?? const <String>[])
          .join(', '),
    );    _videoUrlCtrl = TextEditingController(text: widget.existing?.videoUrl ?? '');

    _selectedRegionId = widget.existing?.regionId;

    _initFuture = _openBoxes();
  }

  Future<void> _openBoxes() async {
    _placesBox = Hive.box<Place>('places');
    _regionsBox = Hive.box<Region>('regions');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imagesCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _workingHoursCtrl.dispose();
    _ticketPriceCtrl.dispose();
    _addressCtrl.dispose();
    _categoriesCtrl.dispose();
    _subcategoriesCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Редактировать место' : 'Добавить место'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: _save,
                tooltip: 'Сохранить',
              ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _Section(title: 'Основное'),
                  _TextField(
                    controller: _nameCtrl,
                    label: 'Название *',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
                  ),
                  _TextField(
                    controller: _descCtrl,
                    label: 'Описание',
                    maxLines: 4,
                  ),

                  _Section(title: 'Фотографии'),
                  _TextField(
                    controller: _imagesCtrl,
                    label: 'URL изображений (по одному в строке)',
                    maxLines: 4,
                    hint: 'https://...\nhttps://...\nassets/images/local.jpg',
                  ),

                  _Section(title: 'Видео'),
                  _TextField(
                    controller: _videoUrlCtrl,
                    label: 'Ссылка на видео (RuTube/YouTube/и т.п.)',
                    hint: 'https://rutube.ru/...',
                    keyboardType: TextInputType.url,
                  ),

                  _Section(title: 'Гео и адрес'),
                  Row(
                    children: [
                      Expanded(
                        child: _TextField(
                          controller: _latCtrl,
                          label: 'Широта',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextField(
                          controller: _lngCtrl,
                          label: 'Долгота',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        ),
                      ),
                    ],
                  ),
                  _TextField(
                    controller: _addressCtrl,
                    label: 'Адрес',
                    maxLines: 2,
                  ),

                  _Section(title: 'Режим и цена'),
                  _TextField(
                    controller: _workingHoursCtrl,
                    label: 'Часы работы',
                    hint: 'Ежедневно 09:00–20:00',
                  ),
                  _TextField(
                    controller: _ticketPriceCtrl,
                    label: 'Цена билета',
                    hint: 'Бесплатно / от 500 тг',
                  ),

                  _Section(title: 'Категории'),
                  _TextField(
                    controller: _categoriesCtrl,
                    label: 'Категории (через запятую)',
                    hint: 'Природа, Развлечение',
                  ),
                  _TextField(
                    controller: _subcategoriesCtrl,
                    label: 'Подкатегории (через запятую)',
                    hint: 'Горы, Озёра, Пляжи',
                  ),

                  _Section(title: 'Регион'),
                  ValueListenableBuilder(
                    valueListenable: _regionsBox.listenable(),
                    builder: (context, Box<Region> box, _) {
                      final regions = box.values.toList(growable: false);
                      return DropdownButtonFormField<String>(
                        value: _selectedRegionId,
                        items: [
                          for (final r in regions)
                            DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            )
                        ],
                        onChanged: (v) => setState(() => _selectedRegionId = v),
                        decoration: const InputDecoration(
                          labelText: 'Регион *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Выберите регион' : null,
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.existing?.id ?? const Uuid().v4();


    final images = _splitToList(_imagesCtrl.text);


    final cats = _splitCsv(_categoriesCtrl.text);
    final subs = _splitCsv(_subcategoriesCtrl.text);


    final double? lat = _tryParseDouble(_latCtrl.text);
    final double? lng = _tryParseDouble(_lngCtrl.text);

    final place = Place(
      id: id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imageUrl: images,
      latitude: lat,
      longitude: lng,
      categories: cats,
      subcategories: subs,
      workingHours: _workingHoursCtrl.text.trim(),
      ticketPrice: _ticketPriceCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      videoUrl: _videoUrlCtrl.text.trim().isEmpty ? null : _videoUrlCtrl.text.trim(),
      regionId: _selectedRegionId!,
    );


    await _placesBox.put(id, place);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранено')),
    );
    Navigator.of(context).pop(place);
  }


  List<String> _splitCsv(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<String> _splitToList(String raw) {
    final parts = raw.split(RegExp(r'[\n,]'));
    final list = <String>[];
    for (final p in parts) {
      final t = p.trim();
      if (t.isNotEmpty) list.add(t);
    }
    return list;
  }

  double? _tryParseDouble(String s) {
    final t = s.trim().replaceAll(',', '.');
    return double.tryParse(t);
  }
}


class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
  }) : super(key: key);

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
