// lib/widgets/rutube_player_mobile.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // ✅ Только мобильный WebView

// Имя класса остается тем же
class RuTubePreviewPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? videoId;

  const RuTubePreviewPlayer({super.key, this.videoUrl, this.videoId})
      : assert(videoUrl != null || videoId != null,
  'Нужно передать videoUrl или videoId');

  @override
  State<RuTubePreviewPlayer> createState() => _RuTubePreviewPlayerState();
}

class _RuTubePreviewPlayerState extends State<RuTubePreviewPlayer> {
  WebViewController? _mobileController;
  late final String _watchUrl;

  @override
  void initState() {
    super.initState();

    final resolvedId = _extractId(widget.videoUrl, widget.videoId);
    _watchUrl = 'https://rutube.ru/video/embed/$resolvedId/';

    // ✅ Только мобильная логика
    _mobileController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(_watchUrl));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Только мобильный виджет
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _mobileController == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _mobileController!),
    );
  }

  // Вспомогательный метод
  String _extractId(String? url, String? id) {
    if (id != null && id.isNotEmpty) return id;
    final uri = Uri.tryParse(url ?? '');
    if (uri == null) return '';
    final segs = uri.pathSegments;
    final idx = segs.indexOf('video');
    if (idx >= 0 && idx + 1 < segs.length) return segs[idx + 1];
    return segs.isNotEmpty ? segs.last.replaceAll('/', '') : '';
  }
}