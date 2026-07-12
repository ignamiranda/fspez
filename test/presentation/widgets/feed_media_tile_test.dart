import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/presentation/widgets/feed_media_tile.dart';

void main() {
  testWidgets('FeedMediaTile uses BoxFit.contain', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedMediaTile(
            imageUrl: 'https://example.com/image.jpg',
            onTap: () {},
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
  });
}
