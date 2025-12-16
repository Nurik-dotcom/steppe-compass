import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


Future<void> callPhone(BuildContext context, String raw) async {
  final phones = _splitPhones(raw)
      .map(_normalizePhoneForTelUri)
      .where((p) => p.isNotEmpty)
      .toList();

  if (phones.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Телефон не найден')),
    );
    return;
  }

  if (phones.length > 1) {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Выберите номер'),
            ),
            for (final p in phones)
              ListTile(
                leading: const Icon(Icons.call),
                title: Text(p),
                onTap: () => Navigator.of(context).pop(p),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null) return;
    await _launchTel(context, selected);
    return;
  }

  await _launchTel(context, phones.first);
}

Future<void> _launchTel(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось открыть звонок: $phone')),
    );
  }
}

List<String> _splitPhones(String raw) {
  // делим по ; , / \n
  return raw
      .replaceAll('Тел:', '')
      .replaceAll('тел:', '')
      .replaceAll('Контакты:', '')
      .split(RegExp(r'[;,/\\\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

String _normalizePhoneForTelUri(String s) {

  var out = s.replaceAll(RegExp(r'[^0-9+]'), '');

  if (out.startsWith('8') && out.length >= 10) {

  }
  return out;
}
