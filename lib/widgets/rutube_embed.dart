import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class RutubeEmbed extends StatefulWidget {
  final String videoId;
  const RutubeEmbed({super.key, required this.videoId});

  @override
  State<RutubeEmbed> createState() => _RutubeEmbedState();
}

class _RutubeEmbedState extends State<RutubeEmbed> {
  late final WebViewController _ctrl;

  @override
  void initState() {
    super.initState();
    final html = '''
<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
html,body{margin:0;padding:0;background:#000}
.wrap{position:relative;padding-top:56.25%}
.wrap iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
</style></head><body>
<div class="wrap">
  <iframe src="https://rutube.ru/play/embed/${widget.videoId}"
          allow="autoplay; clipboard-write"
          allowfullscreen></iframe>
</div>
</body></html>
''';
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: _ctrl),
    );
  }
}



