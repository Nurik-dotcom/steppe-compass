// lib/widgets/rutube_player_stub.dart
import 'package:flutter/material.dart';

// Имя класса должно быть ТОЧНО ТАКИМ ЖЕ, как в mobile и web версиях
class RuTubePreviewPlayer extends StatelessWidget {
  final String? videoUrl;
  final String? videoId;

  const RuTubePreviewPlayer({super.key, this.videoUrl, this.videoId});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}