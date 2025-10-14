import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class RutubePreviewPlayer extends StatefulWidget {
  final String videoId;

  const RutubePreviewPlayer({Key? key, required this.videoId}) : super(key: key);

  @override
  State<RutubePreviewPlayer> createState() => _RutubePreviewPlayerState();
}

class _RutubePreviewPlayerState extends State<RutubePreviewPlayer> {
  bool _isPlaying = false;
  String? _thumbnailUrl;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse("https://rutube.ru/play/embed/${widget.videoId}"),
      );
  }

  /// Загружаем превью через API RuTube
  Future<void> _loadThumbnail() async {
    try {
      final response = await http.get(
        Uri.parse("https://rutube.ru/api/video/${widget.videoId}/?format=json"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _thumbnailUrl = data["thumbnail_url"];
        });
      }
    } catch (e) {
      debugPrint("Ошибка загрузки превью: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: WebViewWidget(controller: _controller),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isPlaying = true),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _thumbnailUrl != null
                ? Image.network(
              _thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
            )
                : Container(color: Colors.black26),
            const Icon(
              Icons.play_circle_fill,
              size: 64,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
