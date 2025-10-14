import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

import '../models/region.dart';
import '../screens/region_detail_screen.dart';
import '../widgets/root_shell_host.dart';

const _kBeige = Color(0xFFF5F5DC);

class DirectionsScreen extends StatefulWidget {
  const DirectionsScreen({Key? key}) : super(key: key);

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  late final Box<Region> _regionsBox;

  // Здесь мы указываем ID регионов в том порядке, в котором они должны отображаться
  final _desiredOrder = <String>[
    'astana-region',
    'almaty-region',
    'shymkent-region',
    'turkistan-region',
    'east-kazakhstan-region',
    'mangystau-region',
    'akmola-region',
  ];

  @override
  void initState() {
    super.initState();
    _regionsBox = Hive.box<Region>('regions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBeige,
      body: ValueListenableBuilder(
        valueListenable: _regionsBox.listenable(),
        builder: (context, Box<Region> box, _) {
          final regions = box.values.toList();

          // Сортируем список `regions` на основе нашего шаблона `_desiredOrder`
          regions.sort((a, b) {
            final indexA = _desiredOrder.indexOf(a.id);
            final indexB = _desiredOrder.indexOf(b.id);
            // Если региона нет в нашем списке, он окажется в конце
            if (indexA == -1) return 1;
            if (indexB == -1) return -1;
            return indexA.compareTo(indexB);
          });

          if (regions.isEmpty) {
            return const _EmptyStub();
          }

          // Используем CustomScrollView для динамического AppBar
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: _kBeige,
                surfaceTintColor: _kBeige,
                pinned: true,
                floating: true,
                expandedHeight: 120.0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  centerTitle: false,
                  title: Text(
                    'Направления',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, RootShellHost.bottomGap),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final region = regions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RegionCard(
                          region: region,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RegionDetailScreen(region: region),
                              ),
                            );
                          },
                        ),
                      ).animate().fade(duration: 500.ms, delay: (100 * index).ms).slideY(begin: 0.2);
                    },
                    childCount: regions.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class _RegionCard extends StatefulWidget {
  const _RegionCard({
    Key? key,
    required this.region,
    required this.onTap,
  }) : super(key: key);

  final Region region;
  final VoidCallback onTap;

  @override
  State<_RegionCard> createState() => _RegionCardState();
}

// НОВОЕ: Карточка стала StatefulWidget для управления состоянием нажатия
class _RegionCardState extends State<_RegionCard> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) => setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails details) => setState(() => _isPressed = false);
  void _onTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    // НОВОЕ: Анимация масштабирования при нажатии
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: _buildRegionImage(widget.region.imageUrl),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                            stops: const [0.0, 0.7],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      right: 16,
                      child: Text(
                        widget.region.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            const Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black87),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if ((widget.region.description).trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Text(
                    widget.region.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const _ImagePlaceholder();
    }
    final isNetwork = imageUrl.startsWith('http');
    return isNetwork
        ? Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
    )
        : Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

// НОВОЕ: Улучшенная заглушка с иконкой
class _EmptyStub extends StatelessWidget {
  const _EmptyStub({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: t.disabledColor),
            const SizedBox(height: 16),
            Text(
              'Направлений пока нет',
              style: t.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте их в админ-панели, и они появятся здесь.',
              style: t.textTheme.bodyMedium?.copyWith(color: t.hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}