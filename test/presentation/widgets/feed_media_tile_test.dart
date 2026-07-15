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

  testWidgets('FeedMediaTile has bounded height before image loads (no overflow)',
      (tester) async {
    // The tile should cap its height at maxHeight even when the image hasn't
    // loaded yet. Without this cap the Image (height: double.infinity) tries
    // to be infinitely tall, pushing sibling content off-screen.
    const double maxHeight = 240.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 100, width: double.infinity),
              // No SizedBox wrapping — Column gives unbounded height.
              // FeedMediaTile should still cap itself at maxHeight.
              FeedMediaTile(
                imageUrl: 'https://example.com/unreachable.jpg',
                onTap: () {},
                maxHeight: maxHeight,
              ),
            ],
          ),
        ),
      ),
    );

    // No overflow exception should be thrown (the cap prevents infinite layout).
    expect(tester.takeException(), isNull);

    // The FeedMediaTile's render box should have a finite height.
    final tileRenderBox = tester.renderObject(
      find.byType(FeedMediaTile).first,
    ) as RenderBox;
    expect(tileRenderBox.hasSize, isTrue);
    // The height must be finite (not double.infinity).
    expect(tileRenderBox.size.height.isFinite, isTrue,
        reason: 'FeedMediaTile height must be finite, not infinite');
    // And should be within a reasonable bound (maxHeight + padding).
    expect(tileRenderBox.size.height, lessThanOrEqualTo(maxHeight + 16));
  });

  testWidgets('FeedMediaTile container has maxHeight constraint',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 500,
            child: FeedMediaTile(
              imageUrl: 'https://example.com/unreachable.jpg',
              onTap: () {},
              maxHeight: 140,
            ),
          ),
        ),
      ),
    );

    // Find the innermost Container inside the ClipRRect
    final containers = find.descendant(
      of: find.byType(FeedMediaTile),
      matching: find.byType(Container),
    );

    // At least one of the Containers should have a maxHeight constraint.
    final hasMaxHeight = containers.evaluate().any((element) {
      final widget = element.widget as Container;
      return widget.constraints != null &&
          widget.constraints!.maxHeight < double.infinity;
    });
    expect(hasMaxHeight, isTrue,
        reason:
            'FeedMediaTile should apply a maxHeight constraint to prevent '
            'infinite layout before the image resolves');
  });
}
