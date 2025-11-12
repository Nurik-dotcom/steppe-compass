// lib/widgets/rutube_player_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui; // Импорт для веба
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

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
  late final String _embedUrl;
  late final String _viewType;

  @override
  void initState() {
    super.initState();

    final resolvedId = _extractId(widget.videoUrl, widget.videoId);
    _embedUrl = 'https://rutube.ru/play/embed/$resolvedId';
    _viewType = 'rutube-iframe-${DateTime.now().microsecondsSinceEpoch}';

    // ✅ Только веб-логика
    ui.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = html.IFrameElement()
        ..src = _embedUrl
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen'
        ..allowFullscreen = true;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Только веб-виджет
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: _viewType),
      ),
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