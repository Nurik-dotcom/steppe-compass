
import 'package:flutter/material.dart';

class JsonImportPreviewDialog<T> extends StatefulWidget {
  final List<T> items;
  final String title;
  final String Function(T) primary;
  final String Function(T) secondary;
  final Future<int> Function(List<T> selected, bool overwrite) onImport;

  const JsonImportPreviewDialog({
    super.key,
    required this.items,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.onImport,
  });

  @override
  State<JsonImportPreviewDialog<T>> createState() => _JsonImportPreviewDialogState<T>();
}

class _JsonImportPreviewDialogState<T> extends State<JsonImportPreviewDialog<T>> {
  late List<bool> selected;
  bool overwrite = false;
  bool inProgress = false;
  int? resultCount;

  @override
  void initState() {
    super.initState();
    selected = List<bool>.filled(widget.items.length, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        height: 360,
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected.every((v) => v),
                  onChanged: (v) => setState(() => selected = List<bool>.filled(selected.length, v == true)),
                ),
                const Text('Выбрать всё'),
                const Spacer(),
                Row(
                  children: [
                    const Text('Перезаписывать по ID'),
                    const SizedBox(width: 8),
                    Switch(value: overwrite, onChanged: (v) => setState(() => overwrite = v)),
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (_, i) => CheckboxListTile(
                  value: selected[i],
                  onChanged: (v) => setState(() => selected[i] = v ?? false),
                  title: Text(widget.primary(widget.items[i])),
                  subtitle: Text(widget.secondary(widget.items[i])),
                ),
              ),
            ),
            if (resultCount != null) ...[
              const SizedBox(height: 8),
              Text('Импортировано: $resultCount', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: inProgress ? null : () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton.icon(
          icon: const Icon(Icons.publish),
          label: inProgress ? const Text('Импорт...') : const Text('Импортировать'),
          onPressed: inProgress ? null : () async {
            setState(() { inProgress = true; resultCount = null; });
            final selItems = <T>[];
            for (int i = 0; i < widget.items.length; i++) {
              if (selected[i]) selItems.add(widget.items[i]);
            }
            final count = await widget.onImport(selItems, overwrite);
            setState(() { inProgress = false; resultCount = count; });
          },
        ),
      ],
    );
  }
}
