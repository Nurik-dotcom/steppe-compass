import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

// Мобильный WebView для iOS/Android
import 'package:webview_flutter/webview_flutter.dart';

// ✅ Правильный импорт для Web-регистрации платформенных видов
import 'dart:ui_web' as ui;          // <-- вместо 'dart:ui'

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
  late final String _resolvedId;
  late final String _watchUrl;     // https://rutube.ru/video/<id>/
  late final String _embedUrl;     // https://rutube.ru/play/embed/<id>
  late final String _viewType;     // уникальный ключ для HtmlElementView

  @override
  void initState() {
    super.initState();

    _resolvedId = _extractId(widget.videoUrl, widget.videoId);
    _watchUrl = 'https://rutube.ru/video/$_resolvedId/';
    _embedUrl = 'https://rutube.ru/play/embed/$_resolvedId';

    if (kIsWeb) {
      _viewType = 'rutube-iframe-${DateTime.now().microsecondsSinceEpoch}';

      // ✅ Регистрируем iframe c явными размерами
      ui.platformViewRegistry.registerViewFactory(_viewType, (int _) {
        final iframe = html.IFrameElement()
          ..src = _embedUrl
          ..style.border = '0'
          ..style.width = '100%'     // ✅ фикс для Width warning
          ..style.height = '100%'    // ✅ фикс для Height warning
          ..allow =
              'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen'
          ..allowFullscreen = true;
        return iframe;
      });
      return;
    }

    // Мобилки
    _mobileController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(_watchUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: HtmlElementView(viewType: _viewType),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _mobileController == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _mobileController!),
    );
  }

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
