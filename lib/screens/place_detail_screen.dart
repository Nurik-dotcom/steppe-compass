import 'dart:async';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../utils/call_utils.dart';

import '/services/image_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb; // Добавил kIsWeb
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/root_shell_host.dart';
// Импортируем оба варианта плееров
import '../widgets/rutube_embed.dart';
import '../widgets/rutube_player.dart'; // Твой файл с export ... if ...
import '../models/review.dart';
import '../services/review_service.dart';
import '../models/place.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/likes_service.dart';
import '../widgets/reviews_count_badge.dart';

const Color kPrimaryColor = Color(0xFF000E6B);
const Color kAccentColor = Color(0xFFC0A45B);
const Color kBackgroundColor = Color(0xFFF0EAD6);
const Color kSurfaceColor = Colors.white;
const Color kTextColor = Color(0xFF2C2C2C);
const Color kLightTextColor = Color(0xFF757575);
const Color kChipColor = Color(0xFFE8E8E8);
const Color kShadowColor = Color(0x24000000);

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
                userId: _userId,
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
  final String userId;

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
    required this.userId,
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
        // ✅ Блок "Позвонить" (показываем только если телефон есть)
        // ✅ Блок "Позвонить" (показываем только если телефон есть)
        if (place.phone != null && place.phone!.trim().isNotEmpty) ...[
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Контакты',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontFamily: 'PlayfairDisplay'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () => callPhone(context, place.phone!),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kBackgroundColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: kPrimaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        place.phone!,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Icon(Icons.call, color: kPrimaryColor),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],


        if (place.videoUrl != null && rutubeId != null)
          _VideoSection(videoUrl: place.videoUrl!, rutubeId: rutubeId!, showVideo: showVideo, onToggleVideo: onToggleVideo),
        if (place.latitude != null && place.longitude != null)
          _MapSection(place: place, hasLocationPermission: hasLocationPermission, onMapCreated: onMapCreated),

        _RealReviewsSection(placeId: place.id),
        _ReviewFormSection(placeId: place.id, userId: userId),

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

  const _VideoSection({
    required this.videoUrl,
    required this.rutubeId,
    required this.showVideo,
    required this.onToggleVideo
  });

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
          child: kIsWeb
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            // ИСПРАВЛЕНИЕ: Используем наш универсальный плеер
            child: RuTubePreviewPlayer(
              videoId: rutubeId,
              // videoUrl можно не передавать, если есть ID, или передать widget.videoUrl
            ),
          )
              : AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: showVideo
                ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // Когда видео открыто на телефоне - используем Embed (он чище и без лишнего интерфейса)
              child: RutubeEmbed(videoId: rutubeId),
            )
                : GestureDetector(
              key: const ValueKey('video_preview'),
              onTap: onToggleVideo,
              // ВОЗВРАЩАЕМ ПРЕВЬЮ
              child: Stack(
                children: [
                  // Твой виджет превью
                  RuTubePreviewPlayer(videoUrl: videoUrl, videoId: rutubeId),
                  // Прозрачный слой сверху, чтобы перехватить нажатие
                  // Если его не будет, WebView внутри PreviewPlayer перехватит тап и не даст сработать onToggleVideo
                  Positioned.fill(child: Container(color: Colors.transparent)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FullScreenGallery extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({super.key, required this.images, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              final imageUrl = images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrl),
                heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
              );
            },
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
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
                liteModeEnabled: false,
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
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) {
            return GestureDetector(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenGallery(
                      images: widget.images,
                      initialIndex: i,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: widget.images[i],
                child: Image.network(
                  widget.images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                ),
              ),
            );
          },
        )
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

//===================================================================
// ▼▼▼ СЕКЦИЯ ОТЗЫВОВ (РЕАЛЬНЫЕ ДАННЫЕ) ▼▼▼
//===================================================================

class _RealReviewsSection extends StatefulWidget {
  final String placeId;
  const _RealReviewsSection({required this.placeId});

  @override
  State<_RealReviewsSection> createState() => _RealReviewsSectionState();
}

class _RealReviewsSectionState extends State<_RealReviewsSection> {
  final ReviewService _reviewService = ReviewService();
  late final Stream<List<PlaceReview>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = _reviewService.getReviewsForPlace(widget.placeId, limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Отзывы посетителей',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontFamily: 'PlayfairDisplay'),
              ),
              // Живой счётчик отзывов
              ReviewsCountBadge(placeId: widget.placeId),
            ],
          ),
        ),
        StreamBuilder<List<PlaceReview>>(
          stream: _reviewsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Не удалось загрузить отзывы.'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Отзывов пока нет. Будьте первым!',
                    style: TextStyle(color: kLightTextColor, fontFamily: 'PlayfairDisplay'),
                  ),
                ),
              );
            }
            final reviews = snapshot.data!;
            return ListView.builder(
              itemCount: reviews.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero, // Убираем отступы у ListView
              itemBuilder: (context, index) {
                return _ReviewCard(review: reviews[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PlaceReview review;
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
    // ▼▼▼ ИЗМЕНЕНИЕ: Добавляем CircleAvatar ▼▼▼
    Widget avatar;
    if (review.authorPhotoUrl != null && review.authorPhotoUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(review.authorPhotoUrl!),
        backgroundColor: Colors.grey.shade200,
      );
    } else {
      // Плейсхолдер
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: kPrimaryColor.withOpacity(0.1),
        child: Text(
          review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
          style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. Аватар
              avatar,
              const SizedBox(width: 12),
              // 2. Имя и звезды
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'PlayfairDisplay'),
                    ),
                    const SizedBox(height: 2),
                    _buildStarRating(review.rating),
                  ],
                ),
              ),
            ],
          ),
          // 3. Текст отзыва
          const SizedBox(height: 10),
          Text(review.text, style: const TextStyle(color: kLightTextColor, fontFamily: 'PlayfairDisplay', height: 1.5)),
        ],
      ),
    );
    // ▲▲▲ КОНЕЦ ИЗМЕНЕНИЙ ▲▲▲
  }
}

class _ReviewFormSection extends StatefulWidget {
  final String placeId;
  final String userId;
  const _ReviewFormSection({required this.placeId, required this.userId});

  @override
  State<_ReviewFormSection> createState() => _ReviewFormSectionState();
}

class _ReviewFormSectionState extends State<_ReviewFormSection> {
  final _textController = TextEditingController();
  final ReviewService _reviewService = ReviewService();
  int _currentRating = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_currentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Пожалуйста, поставьте оценку (от 1 до 5 звезд).'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Пожалуйста, напишите текстовый отзыв.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Только авторизованные пользователи могут оставлять отзывы.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ▼▼▼ ИЗМЕНЕНИЕ: Добавляем authorPhotoUrl ▼▼▼
      final newReview = PlaceReview(
        id: '',
        placeId: widget.placeId,
        userId: user.uid,
        authorName: user.displayName ?? user.email ?? 'Аноним', // Улучшенный фолбэк
        authorPhotoUrl: user.photoURL, // <-- Сохраняем URL аватара
        text: _textController.text.trim(),
        rating: _currentRating,
        createdAt: Timestamp.now(),
      );
      // ▲▲▲

      await _reviewService.postReview(newReview);

      _textController.clear();
      setState(() {
        _currentRating = 0;
        FocusScope.of(context).unfocus();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Спасибо за ваш отзыв!'),
          backgroundColor: Colors.green,
        ));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка при отправке: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Не показываем форму, если пользователь не вошел в систему
    if (widget.userId == 'guest') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Text(
          'Войдите в свой профиль, чтобы оставлять отзывы.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'PlayfairDisplay', color: kLightTextColor.withOpacity(0.8)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text(
            'Оставить отзыв',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'PlayfairDisplay'),
          ),
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
                    onPressed: _isSaving ? null : () => setState(() => _currentRating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 5,
                enabled: !_isSaving,
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
                onPressed: _isSaving ? null : _submitReview,
                child: _isSaving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text('Отправить', style: TextStyle(fontFamily: 'PlayfairDisplay')),
              ),
            ],
          ),
        )
      ],
    );
  }
}