import 'package:url_launcher/url_launcher.dart';

Future<void> callPhone(String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: cleaned);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Не удалось открыть звонилку: $phone';
  }
}
