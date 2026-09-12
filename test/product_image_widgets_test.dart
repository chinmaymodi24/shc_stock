import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/widgets/product_image_picker.dart';
import 'package:shc_stock/app/modules/products/widgets/product_thumbnail.dart';

/// A real, valid 1×1 transparent PNG — small enough to inline, but a genuine
/// image `Image.memory` can decode, unlike arbitrary bytes.
final _validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

// ─────────────────────────────────────────────────────────────────────────────
// The two widgets behind the product-photo feature: [ProductThumbnail] (the
// read-only badge on the list row/card) and [ProductImagePicker] (the
// tappable box on the Add/Edit dialog). Both have to survive "no photo" and
// "photo failed to load" without ever looking broken, and the picker's three
// states — empty, freshly picked, existing — have to route taps correctly.
// ─────────────────────────────────────────────────────────────────────────────

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [AppThemeColors.light]),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('ProductThumbnail', () {
    testWidgets('shows the placeholder icon when there is no image', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const ProductThumbnail(imageUrl: null)));
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('shows the placeholder icon for an empty url too', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const ProductThumbnail(imageUrl: '')));
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets(
      'shows the first 4 letters of the fallback label instead of the icon',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const ProductThumbnail(
              imageUrl: null,
              fallbackLabel: 'Ceramic Fiber Blanket',
            ),
          ),
        );
        expect(find.text('CERA'), findsOneWidget);
        expect(find.byIcon(Icons.inventory_2_outlined), findsNothing);
      },
    );

    testWidgets('falls back to the placeholder if the image fails to load', (
      tester,
    ) async {
      // No test server behind this URL — Image.network is guaranteed to hit
      // errorBuilder, exactly like a broken/moved upload would in the app.
      await tester.pumpWidget(
        _host(const ProductThumbnail(imageUrl: '/uploads/does-not-exist.png')),
      );
      // Let the failed network request resolve and errorBuilder take over.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });

  group('ProductImagePicker', () {
    testWidgets('empty state shows "Add Photo" and only one tap target', (
      tester,
    ) async {
      var picks = 0;
      await tester.pumpWidget(
        _host(
          ProductImagePicker(
            pickedBytes: null,
            existingImageUrl: null,
            removed: false,
            onPick: () => picks++,
            onRemove: () {},
            colors: AppThemeColors.light,
          ),
        ),
      );

      expect(find.text('Add Photo'), findsOneWidget);
      // No image yet — the remove (×) badge must not be offered.
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.tap(find.text('Add Photo'));
      expect(picks, 1);
    });

    testWidgets('a freshly picked image previews from bytes and offers '
        'remove', (tester) async {
      var removed = false;
      await tester.pumpWidget(
        _host(
          ProductImagePicker(
            pickedBytes: _validPng,
            existingImageUrl: null,
            removed: false,
            onPick: () {},
            onRemove: () => removed = true,
            colors: AppThemeColors.light,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Add Photo'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(removed, isTrue);
    });

    testWidgets(
      'a picked file that fails to decode shows as broken, not empty, so '
      'remove stays reachable',
      (tester) async {
        await tester.pumpWidget(
          _host(
            ProductImagePicker(
              pickedBytes: Uint8List.fromList(List.generate(16, (i) => i)),
              existingImageUrl: null,
              removed: false,
              onPick: () {},
              onRemove: () {},
              colors: AppThemeColors.light,
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
        expect(find.text('Add Photo'), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'an existing photo the user removed reverts to the empty state',
      (tester) async {
        await tester.pumpWidget(
          _host(
            ProductImagePicker(
              pickedBytes: null,
              existingImageUrl: '/uploads/old-photo.png',
              removed: true,
              onPick: () {},
              onRemove: () {},
              colors: AppThemeColors.light,
            ),
          ),
        );

        expect(find.text('Add Photo'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
      },
    );
  });
}
