import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/widgets/tmdb_poster_image.dart';

void main() {
  for (final path in <String?>[null, '', '/unavailable-poster.jpg']) {
    testWidgets('shows a placeholder for missing or failed poster: $path', (
      tester,
    ) async {
      // Widget tests reject network image requests, exercising errorBuilder.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TmdbPosterImage(posterPath: path, width: 175, height: 265),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
