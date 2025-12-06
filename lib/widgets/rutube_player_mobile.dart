// lib/widgets/rutube_player_mobile.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Импорт для Android-специфичных настроек
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter/foundation.dart';

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

    if (kIsWeb) return;

    final resolvedId = _extractId(widget.videoUrl, widget.videoId);
    _watchUrl = 'https://rutube.ru/play/embed/$resolvedId';


    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
    }

    controller.loadRequest(Uri.parse(_watchUrl));

    _mobileController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(child: Text("Видео недоступно (Web Error)"));
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