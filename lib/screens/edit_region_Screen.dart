import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/region.dart';

class EditRegionScreen extends StatefulWidget {
  final Region? region;

  const EditRegionScreen({Key? key, this.region}) : super(key: key);

  @override
  State<EditRegionScreen> createState() => _EditRegionScreenState();
}

class _EditRegionScreenState extends State<EditRegionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    final region = widget.region;
    _nameController = TextEditingController(text: region?.name ?? '');
    _descriptionController =
        TextEditingController(text: region?.description ?? '');
    _imageUrlController =
        TextEditingController(text: region?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveRegion() {
    if (_formKey.currentState?.validate() != true) return;

    final box = Hive.box<Region>('regions');
    final id = widget.region?.id ?? const Uuid().v4();
    final updatedRegion = Region(
      id: id,
      name: _nameController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      description: _descriptionController.text.trim(),
      places: widget.region?.places ?? [],
    );

    box.put(id, updatedRegion);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.region != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать регион' : 'Добавить регион'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название региона'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL или локальный путь к изображению',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveRegion,
                child: Text(isEditing ? 'Сохранить изменения' : 'Добавить регион'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
