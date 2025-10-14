// lib/screens/article_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Убедитесь, что этот импорт есть

import '../models/place.dart';
import '../widgets/kt_place_card.dart';

const _kBeige = Color(0xFFF5F5DC);

class ArticleScreen extends StatefulWidget {
  final String articleId;
  const ArticleScreen({Key? key, required this.articleId}) : super(key: key);
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _articleFuture;

  @override
  void initState() {
    super.initState();
    _articleFuture = FirebaseFirestore.instance.collection('articles').doc(widget.articleId).get();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _kBeige,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _articleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data() == null) return const Center(child: Text('Не удалось загрузить статью.'));

          final articleData = snapshot.data!.data()!;
          final title = articleData['title'] as String? ?? 'Без заголовка';
          final coverImageUrl = articleData['coverImageUrl'] as String? ?? '';
          final content = articleData['content '] as String? ?? 'Нет содержимого.';
          final relatedPlaceIds = (articleData['relatedPlaceIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                stretch: true,
                backgroundColor: _kBeige,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(left: 48, right: 48, bottom: 16),

                  // ▼▼▼ ДОБАВИЛИ ПАРАЛЛАКС И HERO ▼▼▼
                  collapseMode: CollapseMode.parallax,
                  background: Hero(
                    tag: 'article_image_${widget.articleId}',
                    child: coverImageUrl.isNotEmpty
                        ? Image.network(coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade400))
                        : Container(color: Colors.grey.shade400),
                  ),
                  // ▲▲▲
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownBody(
                    data: content,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(p: theme.textTheme.bodyMedium, h1: theme.textTheme.displayLarge?.copyWith(fontSize: 26), h2: theme.textTheme.headlineMedium, h3: theme.textTheme.headlineMedium?.copyWith(fontSize: 20), blockSpacing: 20.0, listBullet: theme.textTheme.bodyMedium),
                  ),
                ),
              ),
              if (relatedPlaceIds.isNotEmpty)
                _RelatedPlacesSection(placeIds: relatedPlaceIds),
            ],
          );
        },
      ),
    );
  }
}

class _RelatedPlacesSection extends StatelessWidget {
  final List<String> placeIds;
  const _RelatedPlacesSection({required this.placeIds});

  @override
  Widget build(BuildContext context) {
    final placesBox = Hive.box<Place>('places');
    final places = placeIds.map((id) => placesBox.get(id)).whereType<Place>().toList();
    if (places.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text('Упомянутые места', style: Theme.of(context).textTheme.headlineMedium),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: places.length,
              itemBuilder: (context, index) {
                // ▼▼▼ ДОБАВИЛИ АНИМАЦИЮ ▼▼▼
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: KtPlaceCard(place: places[index]),
                )
                    .animate()
                    .fade(duration: 500.ms, delay: (150 * index).ms)
                    .slideX(begin: 0.3, curve: Curves.easeOut);
                // ▲▲▲
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}