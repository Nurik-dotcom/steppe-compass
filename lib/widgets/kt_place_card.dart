import 'package:flutter/material.dart';
import '../models/place.dart';
import '../screens/place_detail_screen.dart';
import '../services/likes_service.dart';

class KtPlaceCard extends StatelessWidget {
  final Place place;
  const KtPlaceCard({Key? key, required this.place}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final likesRemote = LikesServiceRemote();
    final String? img = (place.imageUrl.isNotEmpty) ? place.imageUrl.first : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.94),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // <-- ключ!
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- картинка ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: AspectRatio(
                aspectRatio: 16 / 12,
                child: img == null
                    ? Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xffbbdefb), Color(0xff90caf9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.landscape, size: 56, color: Colors.white70),
                  ),
                )
                    : (img.startsWith('http')
                    ? Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                )
                    : Image.asset(img, fit: BoxFit.cover)),
              ),
            ),

            // --- текст + лайки ---
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff000E6B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 22, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      StreamBuilder<int>(
                        stream: likesRemote.likeCountStream(place.id),
                        builder: (_, snap) => Text(
                          '${snap.data ?? 0}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
