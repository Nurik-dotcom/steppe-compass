import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewsCountBadge extends StatelessWidget {
  final String placeId;
  const ReviewsCountBadge({Key? key, required this.placeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reviewsService = ReviewService();

    return StreamBuilder<int>(
      stream: reviewsService.watchReviewCount(placeId),
      builder: (context, snapshot) {
        // Пока грузится
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('', style: TextStyle(fontSize: 12));
        }

        final count = snapshot.data ?? 0;

        // Можно заморочиться с падежами
        String text;
        if (count == 0) {
          text = 'Нет отзывов';
        } else if (count == 1) {
          text = '1 отзыв';
        } else if (count >= 2 && count <= 4) {
          text = '$count ';
        } else {
          text = '$count';
        }

        return Text(
          text,
          style: const TextStyle(fontSize: 12),
        );
      },
    );
  }
}
