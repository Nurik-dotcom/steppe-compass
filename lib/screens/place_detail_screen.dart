// lib/screens/place_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../widgets/root_shell_host.dart';
import '../widgets/rutube_embed.dart';
import '../widgets/rutube_preview_player.dart';

import '../models/place.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/likes_service.dart';

// ===================================================================
// ✨ НАСТРОЙКИ ДИЗАЙНА И ТЕМА ✨
// ===================================================================

const Color kPrimaryColor = Color(0xFF000E6B);
const Color kAccentColor = Color(0xFFC0A45B);
const Color kBackgroundColor = Color(0xFFF0EAD6);
const Color kSurfaceColor = Colors.white;
const Color kTextColor = Color(0xFF2C2C2C);
const Color kLightTextColor = Color(0xFF757575);
const Color kChipColor = Color(0xFFE8E8E8);
const Color kShadowColor = Color(0x24000000);

// ▼▼▼ ИЗМЕНЕНИЕ: Модель FakeReview теперь с рейтингом ▼▼▼
class FakeReview {
  final String author;
  final String text;
  final int rating; // было likes
  const FakeReview({required this.author, required this.text, required this.rating});
}
// ▲▲▲

// ▼▼▼ ИЗМЕНЕНИЕ: Данные теперь содержат rating вместо likes ▼▼▼
final Map<String, List<FakeReview>> fakeReviewsData = {
  'zailiyskiy-alatau': [
    const FakeReview(author: 'Алексей', text: 'Невероятное место, дух захватывает! Поднимались на фуникулере на Шымбулак, виды просто космические. Обязательно к посещению.', rating: 5),
    const FakeReview(author: 'Мария', text: 'Очень красиво, но летом было слишком жарко. Обязательно берите с собой много воды и головной убор.', rating: 4),
    const FakeReview(author: 'Тимур', text: 'Прошли по тропе до водопада. Несложный маршрут, подходит для всей семьи. Воздух чистейший!', rating: 5),
  ],
  'kolsai-lakes': [
    const FakeReview(author: 'Виктор', text: 'Чистейший воздух и вода изумрудного цвета. Поднимались ко второму озеру, вид оттуда просто фантастический. Рекомендую!', rating: 5),
    const FakeReview(author: 'Елена', text: 'Конная прогулка вдоль озера - это незабываемо! Лошади спокойные, инструкторы опытные. Подходит даже для новичков.', rating: 5),
  ],
  'charyn-canyon': [
    const FakeReview(author: 'Игорь', text: 'Марсианские пейзажи! Лучше всего приезжать на закате, цвета просто нереальные. Фотографии получаются 🔥.', rating: 5),
    const FakeReview(author: 'Светлана', text: 'Дорога занимает время, но оно того стоит. Внизу у реки есть небольшое кафе, можно перекусить и отдохнуть.', rating: 4),
  ],
  'bayterek-monument': [
    const FakeReview(author: 'Айгерим', text: 'Символ столицы! Обязательно поднимитесь наверх, чтобы приложить руку к оттиску ладони президента и посмотреть на город.', rating: 5),
    const FakeReview(author: 'Дмитрий', text: 'Красиво и днем, и ночью, когда включается подсветка. Очереди бывают большими, лучше приходить в будний день утром.', rating: 4),
  ],
  'medeo-high-mountain-rink': [
    const FakeReview(author: 'Карина', text: 'Кататься на коньках в окружении гор - это сказка! Лед отличный, атмосфера праздничная. Зимой просто обязательно к посещению.', rating: 5),
    const FakeReview(author: 'Арман', text: 'Летом здесь проходят крутые концерты. Акустика в ущелье особенная. Проверяйте афишу!', rating: 4),
  ],
  'bozzhyra-ustyurt': [
    const FakeReview(author: 'Станислав', text: 'Это другая вселенная. Белые скалы посреди степи. Добираться только на внедорожнике с опытным гидом, но виды окупают все сложности.', rating: 5),
    const FakeReview(author: 'Ольга', text: 'Ночевали в палатках. Звездное небо здесь такое, какого в городе никогда не увидишь. Абсолютная тишина и величие природы.', rating: 5),
  ],
};
// ▲▲▲


// ===================================================================
// ОСНОВНОЙ ВИДЖЕТ ЭКРАНА
// ===================================================================

class PlaceDetailScreen extends StatefulWidget {
  final Place place;
  const PlaceDetailScreen({Key? key, required this.place}) : super(key: key);

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _pageController = PageController();
  GoogleMapController? _mapController;
  final _likesRemote = LikesServiceRemote();
  bool _showVideo = false;
  String? _rutubeId;
  bool _hasLocationPermission = false;
  Position? _currentPosition;
  double? _distanceMeters;
  String _userId = 'guest';

  @override
  void initState() {
    super.initState();
    _rutubeId = _rutubeIdFromUrl(widget.place.videoUrl);
    _initUser();
    _initLocationAndDistance();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (mounted && user != null) {
      setState(() => _userId = user.uid);
    }
  }

  Future<void> _ensureLocationPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    setState(() {
      _hasLocationPermission = (perm == LocationPermission.always || perm == LocationPermission.whileInUse);
    });
  }

  Future<void> _initLocationAndDistance() async {
    await _ensureLocationPermission();
    if (!_hasLocationPermission) return;

    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        if (widget.place.latitude != null && widget.place.longitude != null) {
          _distanceMeters = Geolocator.distanceBetween(pos.latitude, pos.longitude, widget.place.latitude!, widget.place.longitude!);
        }
      });
    } catch (e) {
      debugPrint('initLocation error: $e');
    }
  }

  String _formatDistance(double m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} км';
    return '${m.toStringAsFixed(0)} м';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: kBackgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white, size: 28),
            actionsIconTheme: const IconThemeData(color: Colors.white, size: 28),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _PhotosCarousel(images: widget.place.imageUrl, controller: _pageController),
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: FavoritesService.listenable(_userId),
                builder: (_, __, ___) {
                  final isFav = FavoritesService.isFavorite(_userId, widget.place.id);
                  return CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      tooltip: isFav ? 'Убрать из избранного' : 'В избранное',
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                      onPressed: () => FavoritesService.toggle(_userId, widget.place.id),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _ContentSheet(
                place: widget.place,
                distanceText: _distanceMeters == null ? null : _formatDistance(_distanceMeters!),
                likesService: _likesRemote,
                rutubeId: _rutubeId,
                showVideo: _showVideo,
                onToggleVideo: () => setState(() => _showVideo = !_showVideo),
                hasLocationPermission: _hasLocationPermission,
                onMapCreated: (c) => _mapController = c,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentSheet extends StatelessWidget {
  final Place place;
  final String? distanceText;
  final LikesServiceRemote likesService;
  final String? rutubeId;
  final bool showVideo;
  final VoidCallback onToggleVideo;
  final bool hasLocationPermission;
  final void Function(GoogleMapController) onMapCreated;

  const _ContentSheet({
    Key? key,
    required this.place,
    this.distanceText,
    required this.likesService,
    this.rutubeId,
    required this.showVideo,
    required this.onToggleVideo,
    required this.hasLocationPermission,
    required this.onMapCreated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: textTheme.headlineSmall?.copyWith(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _InfoChips(address: place.address, workingHours: place.workingHours, ticketPrice: place.ticketPrice, distanceText: distanceText),
              const SizedBox(height: 12),
              _LikesSection(likesService: likesService, placeId: place.id),
            ],
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(place.description, style: textTheme.bodyMedium?.copyWith(fontFamily: 'PlayfairDisplay', fontSize: 14, height: 1.6)),
        ),
        if (place.videoUrl != null && rutubeId != null)
          _VideoSection(videoUrl: place.videoUrl!, rutubeId: rutubeId!, showVideo: showVideo, onToggleVideo: onToggleVideo),
        if (place.latitude != null && place.longitude != null)
          _MapSection(place: place, hasLocationPermission: hasLocationPermission, onMapCreated: onMapCreated),
        if (fakeReviewsData.containsKey(place.id))
          _FakeReviewsSection(reviews: fakeReviewsData[place.id]!)
        else
          const _ReviewFormSection(),
        SizedBox(height: RootShellHost.bottomGap + 20),
      ],
    ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut).fadeIn();
  }
}

class _LikesSection extends StatelessWidget {
  const _LikesSection({required this.likesService, required this.placeId});
  final LikesServiceRemote likesService;
  final String placeId;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<bool>(
          stream: likesService.isLikedStream(placeId),
          builder: (context, snapLiked) {
            final liked = snapLiked.data ?? false;
            return ActionChip(
              avatar: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20, color: liked ? kSurfaceColor : kPrimaryColor),
              label: const Text('Нравится'),
              backgroundColor: liked ? kPrimaryColor : kChipColor,
              labelStyle: TextStyle(fontFamily: 'PlayfairDisplay', color: liked ? kSurfaceColor : kTextColor, fontWeight: FontWeight.bold),
              onPressed: () => likesService.toggleLike(placeId),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            );
          },
        ),
        const SizedBox(width: 8),
        StreamBuilder<int>(
          stream: likesService.likeCountStream(placeId),
          builder: (context, snapCount) {
            final count = snapCount.data ?? 0;
            return Text('$count', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kPrimaryColor, fontFamily: 'PlayfairDisplay'));
          },
        ),
      ],
    );
  }
}

class _VideoSection extends StatelessWidget {
  final String videoUrl;
  final String rutubeId;
  final bool showVideo;
  final VoidCallback onToggleVideo;
  const _VideoSection({required this.videoUrl, required this.rutubeId, required this.showVideo, required this.onToggleVideo});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('Видеообзор', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'PlayfairDisplay')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: showVideo
                ? _RutubeLazyPlayer(url: videoUrl, key: const ValueKey('video_open'))
                : GestureDetector(key: const ValueKey('video_preview'), onTap: onToggleVideo, child: RutubePreviewPlayer(videoId: rutubeId)),
          ),
        ),
      ],
    );
  }
}

class _MapSection extends StatelessWidget {
  final Place place;
  final bool hasLocationPermission;
  final void Function(GoogleMapController) onMapCreated;
  const _MapSection({required this.place, required this.hasLocationPermission, required this.onMapCreated});
  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(place.latitude!, place.longitude!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('На карте', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'PlayfairDisplay')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                liteModeEnabled: !kReleaseMode,
                myLocationEnabled: hasLocationPermission,
                myLocationButtonEnabled: hasLocationPermission,
                initialCameraPosition: CameraPosition(target: latLng, zoom: 12.5),
                onMapCreated: onMapCreated,
                markers: {Marker(markerId: const MarkerId('place'), position: latLng)},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotosCarousel extends StatefulWidget {
  const _PhotosCarousel({required this.images, required this.controller});
  final List<String> images;
  final PageController controller;
  @override
  State<_PhotosCarousel> createState() => _PhotosCarouselState();
}

class _PhotosCarouselState extends State<_PhotosCarousel> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const _ImagePlaceholder();
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: widget.controller,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: widget.images.length,
          itemBuilder: (_, i) => Image.network(widget.images[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ImagePlaceholder()),
        ),
        IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], stops: const [0.0, 0.4], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
        Positioned(bottom: 35, left: 0, right: 0, child: _Dots(count: widget.images.length, index: _index)),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(count, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, margin: const EdgeInsets.symmetric(horizontal: 4), height: 8, width: i == index ? 24 : 8, decoration: BoxDecoration(color: i == index ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4)))));
  }
}

class _InfoChips extends StatelessWidget {
  final String? address, workingHours, ticketPrice, distanceText;
  const _InfoChips({this.address, this.workingHours, this.ticketPrice, this.distanceText});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (address != null) _chip(context, Icons.location_on_outlined, address!),
        if (workingHours != null) _chip(context, Icons.access_time, workingHours!),
        if (ticketPrice != null) _chip(context, Icons.confirmation_number_outlined, ticketPrice!),
        if (distanceText != null) _chip(context, Icons.route_outlined, distanceText!),
      ],
    );
  }
  Widget _chip(BuildContext context, IconData icon, String text) {
    return Chip(avatar: Icon(icon, size: 20, color: kPrimaryColor), label: Text(text, style: const TextStyle(fontFamily: 'PlayfairDisplay')), backgroundColor: kChipColor);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).colorScheme.surfaceVariant, child: Center(child: Icon(Icons.landscape_outlined, size: 64, color: Theme.of(context).colorScheme.outline)));
  }
}

String? _rutubeIdFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final patterns = [RegExp(r'rutube\.ru/(?:video|shorts)/([A-Za-z0-9_-]+)/?'), RegExp(r'rutube\.ru/play/embed/([A-Za-z0-9_-]+)')];
  for (final p in patterns) { final m = p.firstMatch(url); if (m != null) return m.group(1); }
  return null;
}

class _RutubeLazyPlayer extends StatefulWidget {
  final String url;
  const _RutubeLazyPlayer({required this.url, Key? key}) : super(key: key);
  @override
  State<_RutubeLazyPlayer> createState() => _RutubeLazyPlayerState();
}

class _RutubeLazyPlayerState extends State<_RutubeLazyPlayer> {
  WebViewController? _controller;
  bool _isReady = false, _hasError = false;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted)..setBackgroundColor(const Color(0x00000000))..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => setState(() => _isReady = true), onWebResourceError: (error) { debugPrint('WebView error: ${error.description}'); setState(() => _hasError = true); }))..loadRequest(Uri.parse(widget.url));
  }
  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 16 / 9, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(alignment: Alignment.center, children: [if (_controller != null) WebViewWidget(controller: _controller!), if (_hasError) const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, color: kLightTextColor, size: 48), SizedBox(height: 8), Text('Не удалось загрузить видео', style: TextStyle(fontFamily: 'PlayfairDisplay', color: kLightTextColor))]) else if (!_isReady) const CircularProgressIndicator(color: kPrimaryColor)])));
  }
}

//===================================================================
// ▼▼▼ ПОЛНОСТЬЮ ОБНОВЛЕННАЯ СЕКЦИЯ ОТЗЫВОВ ▼▼▼
//===================================================================

class _FakeReviewsSection extends StatelessWidget {
  final List<FakeReview> reviews;
  const _FakeReviewsSection({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('Отзывы посетителей', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'PlayfairDisplay')),
        ),
        ...reviews.map((review) => _ReviewCard(review: review)).toList(),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FakeReview review;
  const _ReviewCard({required this.review});

  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'PlayfairDisplay')),
              _buildStarRating(review.rating),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.text, style: const TextStyle(color: kLightTextColor, fontFamily: 'PlayfairDisplay', height: 1.5)),
        ],
      ),
    );
  }
}

class _ReviewFormSection extends StatefulWidget {
  const _ReviewFormSection();

  @override
  State<_ReviewFormSection> createState() => _ReviewFormSectionState();
}

class _ReviewFormSectionState extends State<_ReviewFormSection> {
  final _textController = TextEditingController();
  int _currentRating = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text('Оставить отзыв', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'PlayfairDisplay')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _currentRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _currentRating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'PlayfairDisplay'),
                decoration: InputDecoration(
                  hintText: 'Поделитесь впечатлениями...',
                  hintStyle: const TextStyle(fontFamily: 'PlayfairDisplay'),
                  filled: true,
                  fillColor: kBackgroundColor.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Спасибо за ваш отзыв с оценкой $_currentRating!'))),
                child: const Text('Отправить', style: TextStyle(fontFamily: 'PlayfairDisplay')),
              ),
            ],
          ),
        )
      ],
    );
  }
}